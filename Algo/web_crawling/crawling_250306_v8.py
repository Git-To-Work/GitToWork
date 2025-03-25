import json
import os
import re
import time
import random
import requests

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# --- 유틸 함수들 ---

def parse_total_sales(text):
    """
    "매출액 78조 3백억원" 또는 "매출액 2013억 4천만원"과 같은 문자열에서
    총 매출액을 백만원 단위의 정수로 반환합니다.
    """
    text = text.replace("매출액", "").strip()
    matches = re.findall(r'(\d+(?:\.\d+)?)(백)?(조|억|천만원)', text)
    total_eok = 0.0  # 억 단위로 계산
    for num, is_hundred, unit in matches:
        value = float(num)
        if unit == "조":
            total_eok += value * 10000  # 1조 = 10000억
        elif unit == "억":
            if is_hundred:
                total_eok += value * 100
            else:
                total_eok += value
        elif unit == "천만원":
            total_eok += value * 0.1  # 10천만원 = 1억
    return int(total_eok * 100)  # 1억 = 100 백만원

def extract_benefits(benefit_soup):
    """
    benefits 페이지의 HTML에서 복리후생 정보를 파싱합니다.
    반환 형식은 {"title": "복리후생", "sections": [{ "head": ..., "body": [...] }, ...]} 입니다.
    만약 benefits 영역이 없으면 빈 dict를 반환합니다.
    """
    benefits_container = benefit_soup.select_one("div.benefit-list")
    if not benefits_container:
        return {}
    
    sections = []
    groups = benefits_container.select("div.benefit-item-group")
    for group in groups:
        items = group.select("div.item")
        for item in items:
            head_tag = item.select_one("div.benefit-header")
            body_tags = item.select("div.benefit-body p")
            head = head_tag.get_text(strip=True) if head_tag else ""
            body = [p.get_text(strip=True) for p in body_tags if p.get_text(strip=True)]
            if head or body:
                sections.append({"head": head, "body": body})
    return {"title": "복리후생", "sections": sections} if sections else {}

# --- 메인 크롤링 코드 ---

# 저장 폴더 생성
os.makedirs("./crawling", exist_ok=True)
os.makedirs("./crawling_img", exist_ok=True)

chrome_options = Options()
chrome_options.add_argument("--headless")  # 디버깅 시 일반 모드로 실행
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")

driver = webdriver.Chrome(options=chrome_options)
wait = WebDriverWait(driver, 10)

# 1페이지 리스트 URL
list_url = ("https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2&indsCtgrCode=&indsCode=&jobTypeCode=10031"
            "&haveAGI=0&orderCode=2&coPage=1#salarySearchCompany")
driver.get(list_url)
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
time.sleep(3)
print("리스트 페이지 로딩 완료. HTML 파싱 시작.")

soup = BeautifulSoup(driver.page_source, "html.parser")
company_items = soup.select("#listCompany li")
print(f"기업 개수: {len(company_items)}개")

# 리스트 페이지에서 상세 페이지 URL과 로고 URL 추출 (순서대로 저장)
detail_urls = []
logo_urls = []
for item in company_items:
    # 상세 페이지 URL
    a_tag = item.find("a", href=True)
    if a_tag:
        url = "https://www.jobkorea.co.kr" + a_tag["href"]
        detail_urls.append(url)
    # 로고 URL 추출: <div class="thumbnail"> 내 <img> 태그
    thumbnail = item.select_one("div.thumbnail")
    if thumbnail:
        img_tag = thumbnail.find("img")
        if img_tag and img_tag.has_attr("src"):
            raw_src = img_tag["src"].strip()
            # src가 // 로 시작하면 https: 접두사 추가
            logo_url = raw_src if raw_src.startswith("http") else "https:" + raw_src
            logo_urls.append(logo_url)
        else:
            logo_urls.append("")  # 없는 경우 빈 문자열
    else:
        logo_urls.append("")

# 페이지 순회(여기서는 1페이지만 진행)
print("\n[1페이지 상세 정보 수집]")
# idx를 이용해 로고 URL와 상세 URL 매칭
for idx, detail_url in enumerate(detail_urls):
    try:
        driver.get(detail_url)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-table")))
        time.sleep(random.uniform(5, 7))
        
        detail_soup = BeautifulSoup(driver.page_source, "html.parser")
        
        # 회사명 추출 및 정제 ("㈜", "(주)", "주식회사 " 제거)
        header_tag = detail_soup.select_one("div.companyHeader h1.header a")
        company_name_raw = header_tag.get_text(strip=True) if header_tag else "정보없음"
        company_name = re.sub(r'(㈜|\(주\)|주식회사\s*)', '', company_name_raw).strip()
        
        # 사원수 및 총 매출액 추출
        summary_items = detail_soup.select("div.companyHeader div.summary div.item")
        head_count = None
        total_sales_value = None
        for s in summary_items:
            text = s.get_text()
            if "사원" in text:
                match = re.search(r'([\d,]+)', text)
                if match:
                    head_count = int(match.group(1).replace(",", ""))
            elif "매출액" in text:
                total_sales_value = parse_total_sales(text)
        
        # 전체 평균 연봉
        avg_section = detail_soup.select_one("div.salary-table-item.salary-table-average")
        all_avg_salary = None
        if avg_section:
            value_tag = avg_section.select_one("div.salary div.value")
            if value_tag:
                all_avg_salary = int(value_tag.get_text(strip=True).replace(",", ""))
        
        # 신입사원 초봉
        newcomer_section = detail_soup.select_one("div.salary-table-item.salary-table-newcomer")
        newcomer_avg_salary = None
        if newcomer_section:
            value_tag = newcomer_section.select_one("div.salary div.value")
            if value_tag:
                newcomer_avg_salary = int(value_tag.get_text(strip=True).replace(",", ""))
        
        # category 추출
        category = []
        for s in summary_items:
            strong_tag = s.find("strong")
            if strong_tag:
                strong_text = strong_tag.get_text(strip=True)
                clean_text = re.sub(r'\s*\d+위$', '', strong_text)
                category = [cat.strip() for cat in clean_text.split("·") if cat.strip()]
                break
        
        # employeeRatio 추출 (없을 수 있음)
        employeeRatio = {}
        ratio_container = detail_soup.select_one("div.ratio")
        if ratio_container:
            man_tag = ratio_container.select_one("div.item-man div.percent")
            woman_tag = ratio_container.select_one("div.item-woman div.percent")
            try:
                if man_tag:
                    employeeRatio["male"] = int(man_tag.get_text(strip=True).replace("%", ""))
                if woman_tag:
                    employeeRatio["female"] = int(woman_tag.get_text(strip=True).replace("%", ""))
            except Exception as ex:
                print("   employeeRatio 변환 오류:", ex)
        
        # likes 추출
        likes = None
        likes_tag = detail_soup.select_one("div.add-ons div.dibs div.count")
        if likes_tag:
            try:
                likes = int(likes_tag.get_text(strip=True).replace(",", ""))
            except Exception as ex:
                print("   likes 변환 오류:", ex)
        
        # benefits 추출: benefits 페이지 (상세 페이지 URL에서 "/Salary" 제거하고 "?tabType=I" 추가)
        benefits = {}
        benefit_url = re.sub(r'/Salary', '', detail_url) + "?tabType=I"
        try:
            driver.get(benefit_url)
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.benefit-list")))
            benefit_soup = BeautifulSoup(driver.page_source, "html.parser")
            benefits = extract_benefits(benefit_soup)
        except Exception as ex:
            print("   benefits 없음 또는 추출 오류:", ex)
            benefits = {}
        
        # 로고 다운로드: 리스트 페이지에서 추출한 로고_urls의 해당 인덱스 사용
        logo_url = logo_urls[idx] if idx < len(logo_urls) else ""
        logo_file = ""
        if logo_url:
            try:
                res = requests.get(logo_url, stream=True)
                if res.status_code == 200:
                    # 확장자 추출 (기본 jpg)
                    ext = os.path.splitext(logo_url)[1]
                    if not ext:
                        ext = ".jpg"
                    safe_logo_name = re.sub(r'[\\/*?:"<>|]', "_", company_name)
                    logo_file = f"{safe_logo_name}{ext}"
                    logo_path = os.path.join("./crawling_img", logo_file)
                    with open(logo_path, "wb") as img_f:
                        for chunk in res.iter_content(1024):
                            img_f.write(chunk)
                    print(f"   로고 저장 완료: {logo_path}")
                else:
                    print("   로고 다운로드 실패:", logo_url)
            except Exception as ex:
                print("   로고 다운로드 오류:", ex)
        
        # 최종 JSON 구성
        company_data = {
            "companyName": company_name,
            "headCount": head_count,
            "salary": {
                "allAvg": all_avg_salary,
                "newcomerAvg": newcomer_avg_salary,
                "unit": "만원"
            },
            "category": category,
            "employeeRatio": employeeRatio,
            "totalSales": {
                "value": total_sales_value,
                "unit": "백만원"
            },
            "likes": likes,
            "benefits": benefits,
            "logo": logo_file  # 로컬 저장된 이미지 파일명
        }
        
        safe_company_name = re.sub(r'[\\/*?:"<>|]', "_", company_name)
        file_path = os.path.join("./crawling", f"{safe_company_name}.json")
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(company_data, f, ensure_ascii=False, indent=4)
        print(f"   파일 저장 완료: {file_path}")
        
    except Exception as e:
        print("   오류 발생:", e)
        continue

driver.quit()
print("크롤링 완료.")
