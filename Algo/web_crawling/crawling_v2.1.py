import os
import re
import json
import time
import random
import urllib.parse
import requests
from bs4 import BeautifulSoup
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import undetected_chromedriver as uc

# --- 유틸 함수들 ---
def parse_total_sales(text):
    text = text.replace("매출액", "").strip()
    matches = re.findall(r'(\d+(?:\.\d+)?)(백)?(조|억|천만원)', text)
    total_eok = 0.0
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

def normalize_company_name(name):
    """파일명 등에서 사용할 수 있도록 회사명을 정제 (특수문자 제거)"""
    return re.sub(r'[\\/*?:"<>|]', "_", name).strip()

def extract_salary_info(salary_soup):
    """연봉정보 페이지에서 대졸초임 등의 정보를 추출 (없으면 빈 dict)"""
    salary_info = {}
    salary_div = salary_soup.select_one("div.salary-average-item")
    if salary_div:
        salary_text = salary_div.get_text(strip=True)
        salary_info["대졸초임"] = salary_text
    return salary_info

def extract_company_info(detail_soup):
    """기업 상세정보 페이지의 기본 정보를 테이블에서 추출하여 dict로 반환"""
    info = {}
    table = detail_soup.select_one("table.table-basic-infomation-primary")
    if not table:
        return info
    rows = table.select("tr.field")
    for row in rows:
        th_tags = row.select("th.field-label")
        td_tags = row.select("td.field-value")
        for th, td in zip(th_tags, td_tags):
            key = th.get_text(strip=True)
            value = " ".join(td.get_text(separator=" ", strip=True).split())
            info[key] = value
    return info

# --- 메인 크롤링 코드 ---
# 저장 폴더 생성
os.makedirs("./collected_crawling_missing", exist_ok=True)
os.makedirs("./collected_crawling_img_missing", exist_ok=True)

# 대상 기업 리스트 로드 (missing_companies.json는 리스트 형태로 저장되어 있다고 가정)
with open("missing_companies.json", "r", encoding="utf-8") as f:
    company_names = json.load(f)
    
print(f"대상 기업 수: {len(company_names)}개")

# undetected_chromedriver 사용 (보안 우회 목적)
options = uc.ChromeOptions()
options.headless = True  # 디버깅 시 False로 변경 가능
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                     "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36")
driver = uc.Chrome(options=options)
wait = WebDriverWait(driver, 10)

# 검색 URL 템플릿 (검색 페이지: tabindex=corp)
search_url_template = "https://www.jobkorea.co.kr/Search/?stext={keyword}&tabType=corp&Page_No=1"

# 실패한 회사, 로고 미존재 회사 저장 리스트
failed_companies = []
no_logo_list = []

for comp in company_names:
    try:
        print(f"\n===== [{comp}] 크롤링 시작 =====")
        # URL 인코딩 처리한 회사명으로 검색 URL 생성
        keyword = urllib.parse.quote(comp)
        search_url = search_url_template.format(keyword=keyword)
        print(f"  검색 URL: {search_url}")
        driver.get(search_url)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#listCompany li")))
        st = random.uniform(3, 6)
        print(f"  검색 페이지 대기: {st:.2f}초")
        time.sleep(st)
        
        search_soup = BeautifulSoup(driver.page_source, "html.parser")
        # 검색 결과 첫번째 항목 선택 (검색 결과의 CSS 셀렉터는 상황에 따라 달라질 수 있음)
        result_item = search_soup.select_one("#listCompany li")
        if not result_item:
            print("  검색 결과 없음!")
            failed_companies.append(comp)
            continue
        
        # 상세 페이지 URL 추출 (첫번째 결과)
        a_tag = result_item.find("a", href=True)
        if a_tag:
            detail_url = "https://www.jobkorea.co.kr" + a_tag["href"]
        else:
            print("  상세 URL 추출 실패!")
            failed_companies.append(comp)
            continue
        
        # 로고 URL 추출 (리스트 내 thumbnail 영역)
        thumbnail = result_item.select_one("div.thumbnail")
        if thumbnail:
            img_tag = thumbnail.find("img")
            if img_tag and img_tag.has_attr("src"):
                raw_src = img_tag["src"].strip()
                logo_url = raw_src if raw_src.startswith("http") else "https:" + raw_src
            else:
                logo_url = ""
        else:
            logo_url = ""
        
        print(f"  상세 페이지 URL: {detail_url}")
        driver.get(detail_url)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-table")))
        st = random.uniform(5, 8)
        print(f"  상세 페이지 대기: {st:.2f}초")
        time.sleep(st)
        
        detail_soup = BeautifulSoup(driver.page_source, "html.parser")
        
        # 회사명 추출 및 정제 ("㈜", "(주)", "주식회사 " 제거)
        header_tag = detail_soup.select_one("div.companyHeader h1.header a")
        company_name_raw = header_tag.get_text(strip=True) if header_tag else "정보없음"
        company_name = re.sub(r'(㈜|\(주\)|주식회사\s*)', '', company_name_raw).strip()
        print(f"  추출 회사명: {company_name}")
        
        # 기업 기본정보 추출 (상세정보 페이지 내 테이블)
        company_info = extract_company_info(detail_soup)
        
        # 요약 영역에서 사원수 및 매출액 추출
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
        
        # 평균 연봉 정보 추출
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
        
        # category 추출
        category = []
        for s in summary_items:
            strong_tag = s.find("strong")
            if strong_tag:
                strong_text = strong_tag.get_text(strip=True)
                clean_text = re.sub(r'\s*\d+위$', '', strong_text)
                category = [cat.strip() for cat in clean_text.split("·") if cat.strip()]
                break
        
        # employeeRatio 추출 (존재하면)
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
                print("  employeeRatio 변환 오류:", ex)
        
        # likes 추출
        likes = None
        likes_tag = detail_soup.select_one("div.add-ons div.dibs div.count")
        if likes_tag:
            try:
                likes = int(likes_tag.get_text(strip=True).replace(",", ""))
            except Exception as ex:
                print("  likes 변환 오류:", ex)
        
        # benefits 추출 (상세 URL에서 "/Salary" 제거 후 "?tabType=I" 추가)
        benefits = {}
        benefit_url = re.sub(r'/Salary', '', detail_url) + "?tabType=I"
        try:
            driver.get(benefit_url)
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.benefit-list")))
            benefit_soup = BeautifulSoup(driver.page_source, "html.parser")
            benefits = extract_benefits(benefit_soup)
        except Exception as ex:
            print("  benefits 없음 또는 추출 오류:", ex)
            benefits = {}
        
        # 연봉정보 페이지 추출 (존재하면)
        salary_info = {}
        # 검색 결과 페이지의 a_tag href에 기업 ID가 포함되어 있음 (예: /Recruit/Co_Read/C/48486)
        m = re.search(r'/C/(\d+)', a_tag["href"])
        if m:
            company_id = m.group(1)
            salary_url = f"https://www.jobkorea.co.kr/Recruit/Salary/{company_id}"
            print(f"  연봉정보 페이지 URL: {salary_url}")
            try:
                driver.get(salary_url)
                wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "div.salary-average-item")))
                st = random.uniform(3, 6)
                print(f"  연봉정보 페이지 대기: {st:.2f}초")
                time.sleep(st)
                salary_soup = BeautifulSoup(driver.page_source, "html.parser")
                salary_info = extract_salary_info(salary_soup)
            except Exception as e:
                print("  연봉정보 없음 또는 추출 오류:", e)
        else:
            print("  회사 ID 추출 실패. 연봉정보 페이지 접근 불가.")
        
        # 로고 다운로드 처리
        safe_company_name = normalize_company_name(company_name)
        logo_file = ""
        if logo_url:
            try:
                res = requests.get(logo_url, stream=True, timeout=10, headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
                })
                if res.status_code == 200:
                    logo_url_clean = logo_url.split('?')[0]
                    ext = os.path.splitext(logo_url_clean)[1]
                    if not ext:
                        ext = ".jpg"
                    logo_file = f"{safe_company_name}{ext}"
                    logo_path = os.path.join("./collected_crawling_img_missing", logo_file)
                    with open(logo_path, "wb") as img_f:
                        for chunk in res.iter_content(1024):
                            img_f.write(chunk)
                    print(f"  {safe_company_name} 로고 저장 완료: {logo_path}")
                else:
                    print(f"  로고 다운로드 실패: {logo_url} (status: {res.status_code})")
                    ext = ".jpg"
                    logo_file = f"{safe_company_name}(로고없음){ext}"
                    logo_path = os.path.join("./collected_crawling_img_missing", logo_file)
                    open(logo_path, "wb").close()
                    print(f"  빈 로고 파일 저장: {logo_path}")
                    no_logo_list.append(safe_company_name)
            except Exception as ex:
                print("  로고 다운로드 오류:", ex)
                ext = ".jpg"
                logo_file = f"{safe_company_name}(로고없음){ext}"
                logo_path = os.path.join("./collected_crawling_img_missing", logo_file)
                open(logo_path, "wb").close()
                print(f"  빈 로고 파일 저장: {logo_path}")
                no_logo_list.append(safe_company_name)
        else:
            print(f"  {safe_company_name} 로고 태그 없음.")
            ext = ".jpg"
            logo_file = f"{safe_company_name}(로고없음){ext}"
            logo_path = os.path.join("./collected_crawling_img_missing", logo_file)
            open(logo_path, "wb").close()
            print(f"  빈 로고 파일 저장: {logo_path}")
            no_logo_list.append(safe_company_name)
        
        # 최종 데이터 구성
        company_data = {
            "companyName": company_name,
            "detailURL": detail_url,
            "companyInfo": extract_company_info(detail_soup),
            "headCount": head_count,
            "salary": {
                "allAvg": all_avg_salary,
                "newcomerAvg": newcomer_avg_salary,
                "unit": "만원"
            },
            "salaryInfo": salary_info,
            "category": category,
            "employeeRatio": employeeRatio,
            "totalSales": {
                "value": total_sales_value,
                "unit": "백만원"
            },
            "likes": likes,
            "benefits": benefits,
            "logo": logo_file
        }
        
        file_name = f"{safe_company_name}.json"
        file_path = os.path.join("./collected_crawling_missing", file_name)
        with open(file_path, "w", encoding="utf-8") as f_out:
            json.dump(company_data, f_out, ensure_ascii=False, indent=4)
        print(f"  파일 저장 완료: {file_path}")
        
        # 다음 회사 전 랜덤 대기 (3~6초)
        time.sleep(random.uniform(3, 6))
        
    except Exception as e:
        print(f"  회사 처리 중 오류 발생: {e}")
        failed_companies.append(comp)
        continue

driver.quit()
print("\n===== 크롤링 완료 =====")
if no_logo_list:
    no_logo_file = os.path.join("./collected_crawling_missing", "missing_logo_companies.json")
    with open(no_logo_file, "w", encoding="utf-8") as f_fail:
        json.dump(no_logo_list, f_fail, ensure_ascii=False, indent=4)
    print(f"  로고 태그 없는 기업 리스트 저장 완료: {no_logo_file}")
else:
    print("  로고 태그 없는 기업은 없습니다.")

if failed_companies:
    fail_file = os.path.join("./collected_crawling_missing", "failed_companies.json")
    with open(fail_file, "w", encoding="utf-8") as f_fail:
        json.dump(failed_companies, f_fail, ensure_ascii=False, indent=4)
    print(f"  크롤링 실패 기업 리스트 저장 완료: {fail_file}")
else:
    print("  모든 기업 크롤링 성공")
