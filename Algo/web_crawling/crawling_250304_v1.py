import os
import requests
import json
import math

BASE_URL = "https://jumpit-api.saramin.co.kr/api/positions?sort=rsp_rate&page={}"

def parse_page(page):
    url = BASE_URL.format(page)
    response = requests.get(url)
    data = response.json()  # JSON 응답 파싱

    result = data.get("result", {})
    totalCount = result.get("totalCount", 0)
    totalPages = math.ceil(totalCount / 16)

    positions = result.get("positions", [])
    output = []

    for pos in positions:
        job_id = pos.get("id")
        category = pos.get("jobCategory")
        companyName = pos.get("companyName")
        closedAt = pos.get("closedAt", "")
        # "closedAt"의 날짜 부분만 추출
        deadline = closedAt.split("T")[0] if "T" in closedAt else closedAt
        title = pos.get("title")
        techStacks = pos.get("techStacks", [])
        locations = pos.get("locations", [])
        # locations는 리스트 형태이므로, 첫 번째 값만 사용
        location_str = locations[0] if locations else ""
        newcomer = pos.get("newcomer", False)
        minCareer = pos.get("minCareer")
        maxCareer = pos.get("maxCareer")

        output.append({
            "id": job_id,
            "category": category,
            "companyName": companyName,
            "deadline": deadline,
            "title": title,
            "techStacks": techStacks,
            "locations": location_str,
            "newcomer": newcomer,
            "minCareer": minCareer,
            "maxCareer": maxCareer
        })

    return output, totalPages

def save_results(results, directory="jobs"):
    # 저장할 디렉토리가 없으면 생성
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    for entry in results:
        filename = os.path.join(directory, f"job_{entry['id']}.json")
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(entry, f, ensure_ascii=False, indent=4)
        print(f"Saved: {filename}")

# 먼저 1페이지를 호출하여 전체 페이지 수를 확인합니다.
_, totalPages = parse_page(1)
print(f"Total pages: {totalPages}")

# 1페이지부터 마지막 페이지까지 순회하며 데이터를 저장합니다.
for page in range(1, totalPages + 1):
    print(f"Processing page {page}...")
    results, _ = parse_page(page)
    save_results(results)
