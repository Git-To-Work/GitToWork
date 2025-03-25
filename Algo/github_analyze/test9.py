import os
import re
import time
import random
import json
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# 저장 폴더 생성
os.makedirs("./crawling_img", exist_ok=True)

# 로고 태그가 없는 기업들을 저장할 리스트
missing_logo_companies = []

# Selenium 옵션 설정
chrome_options = Options()
chrome_options.add_argument("--headless")  # 디버깅 시 주석 해제 가능
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument(
    "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
)

driver = webdriver.Chrome(options=chrome_options)
wait = WebDriverWait(driver, 10)

# 기본 리스트 페이지 URL (페이지 번호 변경)
base_list_url = (
    "https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2"
    "&indsCtgrCode=&indsCode=&jobTypeCode=10031&haveAGI=0&orderCode=2"
    "&coPage={page}#salarySearchCompany"
)

# 1페이지부터 12페이지까지 반복
for page_no in range(1, 13):
    print(f"\n[페이지 {page_no} 진행 중]")
    list_url = base_list_url.format(page=page_no)
    driver.get(list_url)
    # 리스트 아이템 (#listCompany li)가 로드될 때까지 대기
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
    # 랜덤 대기: 5~15초
    sleep_time = random.uniform(5, 7)
    print(f"  대기 시간: {sleep_time:.2f}초")
    time.sleep(sleep_time)
    
    soup = BeautifulSoup(driver.page_source, "html.parser")
    company_items = soup.select("#listCompany li")
    print(f"  해당 페이지 기업 개수: {len(company_items)}개")
    
    for item in company_items:
        try:
            # 회사명 추출 및 정제 ("㈜", "(주)", "주식회사 " 제거)
            company_name_tag = item.select_one("div.thumbnail div.inner")
            if company_name_tag:
                company_name_raw = company_name_tag.get_text(strip=True)
                clean_company_name = re.sub(r'(㈜|\(주\)|주식회사\s*)', '', company_name_raw).strip()
                safe_company_name = re.sub(r'[\\/*?:"<>|]', "_", clean_company_name)
            else:
                safe_company_name = "unknown"
            
            # 로고 이미지 추출
            img_tag = item.select_one("div.thumbnail img")
            if img_tag and img_tag.has_attr("src"):
                raw_src = img_tag["src"].strip()
                # 절대 URL로 변환: http로 시작하지 않으면 "https:" 추가
                logo_url = raw_src if raw_src.startswith("http") else "https:" + raw_src
                print(f"   {safe_company_name} 로고 URL: {logo_url}")
                
                # 쿼리 스트링 제거
                logo_url_clean = logo_url.split('?')[0]
                # 파일 확장자 추출
                ext = os.path.splitext(logo_url_clean)[1]
                if not ext:
                    ext = ".jpg"
                
                logo_file = f"{safe_company_name}{ext}"
                logo_path = os.path.join("./crawling_img", logo_file)
                
                try:
                    res = requests.get(logo_url, stream=True, timeout=10, headers={
                        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
                    })
                    if res.status_code == 200:
                        with open(logo_path, "wb") as f:
                            for chunk in res.iter_content(1024):
                                f.write(chunk)
                        print(f"   로고 저장 완료: {logo_path}")
                    else:
                        print(f"   로고 다운로드 실패: {logo_url} (status: {res.status_code})")
                except Exception as e:
                    print(f"   로고 다운로드 오류: {e}")
            else:
                print(f"   {safe_company_name} 로고 태그 없음.")
                missing_logo_companies.append(safe_company_name)
        except Exception as ex:
            print("   항목 처리 중 오류:", ex)
            continue

driver.quit()
print("이미지 크롤링 완료.")

# 로고 태그가 없는 기업 리스트를 JSON 파일로 저장
with open("missing_logo_companies.json", "w", encoding="utf-8") as f:
    json.dump(missing_logo_companies, f, ensure_ascii=False, indent=4)

print("로고 태그 없음 기업 목록 저장 완료: missing_logo_companies.json")
