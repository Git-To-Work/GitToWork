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

# --- 유틸 함수들 ---

def parse_total_sales(text):
    """
    예시: "매출액 78조 3백억원" 또는 "매출액 2013억 4천만원"에서 
    총 매출액을 백만원 단위의 정수로 반환합니다.
    """
    text = text.replace("매출액", "").strip()
    matches = re.findall(r'(\d+(?:\.\d+)?)(백)?(조|억|천만원)', text)
    total_eok = 0.0  # 억 단위
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
    benefits 영역 파싱: benefits 페이지의 HTML에서 복리후생 정보를 추출
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

chrome_options = Options()
chrome_options.add_argument("--headless")  # 디버깅 시 일반 모드로 실행
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")

driver = webdriver.Chrome(options=chrome_options)
wait = WebDriverWait(driver, 10)

# 첫 페이지 URL (페이지 번호 1)
base_list_url = ("https://www.jobkorea.co.kr/Salary/Index?coKeyword=&tabindex=2&indsCtgrCode=&indsCode="
                 "&jobTypeCode=10031&haveAGI=0&orderCode=2&coPage={page}#salarySearchCompany")
driver.get(base_list_url.format(page=1))
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
time.sleep(3)
print("리스트 페이지 1 로딩 완료. HTML 파싱 시작.")

soup = BeautifulSoup(driver.page_source, "html.parser")
# 총 기업 수는 div.total em에서 가져옴 (예: "총 5,693건 기업의 연봉")
total_text = soup.select_one("div.total em").text.replace(',', '')
total_companies = int(total_text)
per_page = 30  # 한 페이지당 30개 기업
total_pages = round(total_companies / per_page)
print(f"총 기업 수: {total_companies}, 총 페이지 수: {total_pages}")

# 페이지 1부터 총 페이지까지 순회
for page_no in range(1, total_pages + 1):
    current_list_url = base_list_url.format(page=page_no)
    print(f"\n[페이지 {page_no} 수집 중]")
    driver.get(current_list_url)
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
    sleep_time = random.uniform(5, 7)
    print(f"  대기 시간: {sleep_time:.2f}초")
    time.sleep(sleep_time)
    
    page_soup = BeautifulSoup(driver.page_source, "html.parser")
    company_items = page_soup.select("#listCompany li")
    print(f"  페이지 내 기업 개수: {len(company_items)}개")
    
    # 상세 페이지 URL 추출
    detail_urls = []
    for item in company_items:
        a_tag = item.find("a", href=True)
        if a_tag:
            url = "https://www.jobkorea.co.kr" + a_tag["href"]
            detail_urls.append(url)
            print("   상세 페이지 URL:", url)
    
    # 각 상세 페이지 방문
    for detail_url in detail_urls:
        try:
            driver.get(detail_url)
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-table")))
            
            detail_soup = BeautifulSoup(driver.page_source, "html.parser")
            # 회사명 추출 및 정제
            header_tag = detail_soup.select_one("div.companyHeader h1.header a")
            company_name_raw = header_tag.get_text(strip=True) if header_tag else "정보없음"
            company_name = re.sub(r'(㈜|\(주\)|주식회사\s*)', '', company_name_raw).strip()
            
            # 사원수 및 총 매출액
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
            
            # benefits 추출: benefits 페이지 접근 ("/Salary" 제거, "?tabType=I" 추가)
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
            
            print(f"   기업명: {company_name}, 사원수: {head_count}, 전체 평균 연봉: {all_avg_salary}, 신입 연봉: {newcomer_avg_salary}")
            print(f"    category: {category}")
            print(f"    employeeRatio: {employeeRatio}, totalSales: {total_sales_value}, likes: {likes}")
            print(f"    benefits: {benefits if benefits else '없음'}")
            
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
                "benefits": benefits
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
print("전체 크롤링 완료.")
