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
        # "closedAt"에서 날짜 부분만 추출 (예: "2025-03-04")
        deadline = closedAt.split("T")[0] if "T" in closedAt else closedAt
        title = pos.get("title")
        techStacks = pos.get("techStacks", [])
        locations = pos.get("locations", [])
        location_str = locations[0] if locations else ""
        newcomer = pos.get("newcomer", False)
        minCareer = pos.get("minCareer")
        maxCareer = pos.get("maxCareer")
        logo = pos.get("logo")  # 회사 로고 URL

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
            "maxCareer": maxCareer,
            "logo": logo  # JSON에 로고 URL도 함께 저장
        })

    return output, totalPages

def save_results(results, json_directory="jobs", logo_directory="logos"):
    # JSON 파일과 로고 이미지 저장 디렉토리 생성
    if not os.path.exists(json_directory):
        os.makedirs(json_directory)
    if not os.path.exists(logo_directory):
        os.makedirs(logo_directory)
    
    for entry in results:
        # JSON 파일로 저장 (예: jobs/job_43729.json)
        json_filename = os.path.join(json_directory, f"job_{entry['id']}.json")
        with open(json_filename, 'w', encoding='utf-8') as f:
            json.dump(entry, f, ensure_ascii=False, indent=4)
        print(f"Saved JSON: {json_filename}")
        
        # 로고 이미지 다운로드
        logo_url = entry.get("logo")
        if logo_url:
            # URL에서 파일 확장자 추출 (예: webp, jpg 등)
            ext = logo_url.split('.')[-1].split('?')[0]
            logo_filename = os.path.join(logo_directory, f"logo_{entry['id']}.{ext}")
            try:
                r = requests.get(logo_url, stream=True)
                if r.status_code == 200:
                    with open(logo_filename, 'wb') as f:
                        for chunk in r.iter_content(chunk_size=1024):
                            f.write(chunk)
                    print(f"Downloaded logo: {logo_filename}")
                else:
                    print(f"Failed to download logo for job {entry['id']}. Status code: {r.status_code}")
            except Exception as e:
                print(f"Error downloading logo for job {entry['id']}: {e}")

# 1페이지의 데이터를 가져와 저장 (로고 이미지도 함께 다운로드)
json_results, _ = parse_page(1)
save_results(json_results)
