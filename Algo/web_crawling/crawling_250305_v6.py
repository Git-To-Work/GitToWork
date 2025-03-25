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
chrome_options.add_argument("--headless")  # 디버깅 시 일반 모드로 실행
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")

driver = webdriver.Chrome(options=chrome_options)
wait = WebDriverWait(driver, 10)

# 1페이지 URL
list_url = ("https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2&indsCtgrCode=&indsCode="
            "&jobTypeCode=10031&haveAGI=0&orderCode=2&coPage=1#salarySearchCompany")
driver.get(list_url)
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
time.sleep(3)
print("페이지 로딩 완료. HTML 파싱 시작.")

soup = BeautifulSoup(driver.page_source, "html.parser")
company_items = soup.select("#listCompany li")
print(f"기업 개수: {len(company_items)}개")

detail_urls = []
for item in company_items:
    a_tag = item.find("a", href=True)
    if a_tag:
        url = "https://www.jobkorea.co.kr" + a_tag["href"]
        detail_urls.append(url)
        print("상세 페이지 URL:", url)

# 1페이지 내의 모든 기업 상세 페이지 방문
for detail_url in detail_urls:
    try:
        driver.get(detail_url)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-table")))
        time.sleep(random.uniform(5, 15))
        
        detail_soup = BeautifulSoup(driver.page_source, "html.parser")
        
        # 회사명 추출 및 불필요한 단어 제거 ("㈜", "(주)", "주식회사 " 제거)
        header_tag = detail_soup.select_one("div.companyHeader h1.header a")
        company_name_raw = header_tag.get_text(strip=True) if header_tag else "정보없음"
        company_name = re.sub(r'(㈜|\(주\)|주식회사\s*)', '', company_name_raw).strip()
        
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
        
        # category 추출: summary 영역 내 첫 번째 div.item에 있는 <strong> 태그의 텍스트 사용
        category = []
        # 모든 summary 아이템 중 강하게 표기된 텍스트가 있다면 시도
        for s in summary_items:
            strong_tag = s.find("strong")
            if strong_tag:
                strong_text = strong_tag.get_text(strip=True)
                # 만약 trailing에 숫자와 '위'가 있으면 제거, 없으면 그대로 사용
                clean_text = re.sub(r'\s*\d+위$', '', strong_text)
                # "·" 기준으로 분리하고, 각 요소의 좌우 공백 제거
                category = [cat.strip() for cat in clean_text.split("·") if cat.strip()]
                break
        
        print(f"기업명: {company_name}, 사원수: {head_count}, 전체 평균 연봉: {all_avg_salary}, 신입 연봉: {newcomer_avg_salary}, category: {category}")
        
        company_data = {
            "companyName": company_name,
            "headCount": head_count,
            "allAvgSalary": all_avg_salary,
            "newcomerAvgSalary": newcomer_avg_salary,
            "category": category
        }
        
        # 안전한 파일명 생성
        safe_company_name = re.sub(r'[\\/*?:"<>|]', "_", company_name)
        file_path = os.path.join("./crawling", f"{safe_company_name}.json")
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(company_data, f, ensure_ascii=False, indent=4)
        print(f"파일 저장 완료: {file_path}")
        
    except Exception as e:
        print(f"오류 발생: {e}")
        continue

driver.quit()
print("크롤링 완료.")
