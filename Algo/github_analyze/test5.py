import json
import os
import re
import time
import random

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# 저장 폴더 생성 (./crawling)
os.makedirs("./crawling", exist_ok=True)

# Selenium Chrome 옵션 설정 (헤드리스 모드 해제)
chrome_options = Options()
chrome_options.add_argument("--headless")  # 디버깅을 위해 일반 모드로 실행
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")

# 드라이버 생성 후 대기 객체 생성
driver = webdriver.Chrome(options=chrome_options)
wait = WebDriverWait(driver, 10)

# 첫 페이지 URL: 총 건수 파악용
first_page_url = "https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2&indsCtgrCode=&indsCode=&jobTypeCode=10031&haveAGI=0&orderCode=2&coPage=1#salarySearchCompany"
driver.get(first_page_url)
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
time.sleep(3)  # 추가 대기

soup = BeautifulSoup(driver.page_source, "html.parser")
# "총 5,693건 기업의 연봉"은 div.total 내 em 태그에 있음
pages_text = soup.select_one("div.total em").text.replace(',', '')
# 한 페이지에 30개 기업이 노출된다고 가정
total_pages = round(int(pages_text) / 30)
print(f"총 페이지 수: {total_pages}")

# 136페이지부터 시작 (예: 136부터 수집)
start_page = 136

for page_no in range(start_page, total_pages + 1):
    page_url = (f"https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2&indsCtgrCode=&indsCode="
                f"&jobTypeCode=10031&haveAGI=0&orderCode=2&coPage={page_no}#salarySearchCompany")
    print(f"\n[페이지 {page_no} 수집 중]")
    driver.get(page_url)
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
    # 페이지마다 5초~15초 사이의 랜덤 sleep
    sleep_time = random.uniform(5, 15)
    print(f"  Sleep for {sleep_time:.2f} seconds")
    time.sleep(sleep_time)
    
    page_soup = BeautifulSoup(driver.page_source, "html.parser")
    company_items = page_soup.select("#listCompany li")
    print(f"  기업 개수: {len(company_items)}개")
    
    # 해당 페이지의 모든 상세 페이지 URL 추출
    detail_urls = []
    for item in company_items:
        a_tag = item.find("a", href=True)
        if a_tag:
            url = "https://www.jobkorea.co.kr" + a_tag["href"]
            detail_urls.append(url)
            print("   상세 페이지 URL:", url)
    
    # 각 기업 상세 페이지 방문 후 정보 추출 및 개별 JSON 저장
    for detail_url in detail_urls:
        try:
            driver.get(detail_url)
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-table")))
            # 각 상세 페이지 방문 시에도 랜덤 sleep 적용 (옵션)
            sleep_detail = random.uniform(5, 15)
            print(f"   상세 페이지 sleep for {sleep_detail:.2f} seconds")
            time.sleep(sleep_detail)
            
            detail_soup = BeautifulSoup(driver.page_source, "html.parser")
            header_tag = detail_soup.select_one("div.companyHeader h1.header a")
            company_name = header_tag.get_text(strip=True) if header_tag else "정보없음"
            
            # 사원수 추출
            summary_items = detail_soup.select("div.companyHeader div.summary div.item")
            head_count = None
            for s in summary_items:
                text = s.get_text()
                if "사원" in text:
                    match = re.search(r'([\d,]+)', text)
                    if match:
                        head_count = int(match.group(1).replace(",", ""))
                    break
            
            # 전체 평균 연봉 추출
            avg_section = detail_soup.select_one("div.salary-table-item.salary-table-average")
            all_avg_salary = None
            if avg_section:
                value_tag = avg_section.select_one("div.salary div.value")
                if value_tag:
                    all_avg_salary = int(value_tag.get_text(strip=True).replace(",", ""))
            
            # 신입사원 초봉 추출
            newcomer_section = detail_soup.select_one("div.salary-table-item.salary-table-newcomer")
            newcomer_avg_salary = None
            if newcomer_section:
                value_tag = newcomer_section.select_one("div.salary div.value")
                if value_tag:
                    newcomer_avg_salary = int(value_tag.get_text(strip=True).replace(",", ""))
            
            print(f"   기업명: {company_name}, 사원수: {head_count}, 전체 평균 연봉: {all_avg_salary}, 신입 연봉: {newcomer_avg_salary}")
            
            company_data = {
                "companyName": company_name,
                "headCount": head_count,
                "allAvgSalary": all_avg_salary,
                "newcomerAvgSalary": newcomer_avg_salary
            }
            
            # 파일명에 사용할 수 없는 문자는 '_'로 치환
            safe_company_name = re.sub(r'[\\/*?:"<>|]', "_", company_name)
            file_path = os.path.join("./crawling", f"{safe_company_name}.json")
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(company_data, f, ensure_ascii=False, indent=4)
            print(f"   파일 저장 완료: {file_path}")
            
        except Exception as e:
            print(f"   오류 발생: {e}")
            continue

driver.quit()
print("전체 크롤링 완료.")
