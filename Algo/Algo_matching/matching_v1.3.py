import os
import json
from glob import glob
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

############################
# 1) 설정 및 사용자 로딩
############################

username = "chanhoan"

# 좋아요 / 싫어요 기업 (예시)
liked_companies = {"현대자동차"}      # 사용자에게 '좋아요' 표시된 기업
disliked_companies = {"에프엘이에스"}  # 사용자에게 '싫어요' 표시된 기업

# 가중치
ALPHA = 0.3  # 좋아요 기업 유사도 보너스
BETA = 0.3   # 싫어요 기업 유사도 패널티

# ─────────────────────────────────────────────────────────────────
# 사용자 GitHub 분석 JSON 로딩
# ─────────────────────────────────────────────────────────────────
import_path = f"./user/{username}"
json_files = glob(os.path.join(import_path, "*.json"))
if not json_files:
    raise FileNotFoundError(f"{import_path} 내에 사용자 분석 JSON이 없습니다.")

with open(json_files[0], "r", encoding="utf-8") as f:
    user_data = json.load(f)

# GitHub 언어별 커밋 수를 문자열로 반복 -> 사용자 프로필 텍스트
user_languages = user_data.get("language_commit_metrics", {})
user_profile_text = []
for lang, info in user_languages.items():
    count = info.get("commit_count", 0)
    user_profile_text.append((lang + " ") * count)
user_profile_text = " ".join(user_profile_text)

############################
# 2) 공고 및 기업 로딩
############################
jobs = []
for job_file in glob("./jobs/*.json"):
    with open(job_file, "r", encoding="utf-8") as f:
        jobs.append(json.load(f))

companies = {}
for comp_file in glob("./crawling/*.json"):
    with open(comp_file, "r", encoding="utf-8") as f:
        comp_data = json.load(f)
        c_name = comp_data.get("companyName")
        if c_name:
            companies[c_name] = comp_data

############################
# 3) 기업 프로필 텍스트 생성
############################
# 기업이 가진 모든 공고의 techStacks를 합쳐서 하나의 텍스트로 만든다.
# 예: {"현대자동차": "Python C++ Java ..."}
company_profiles = {}

for c_name in companies.keys():
    # 해당 기업의 모든 공고를 찾는다
    tech_stack_list = []
    for job in jobs:
        if job.get("companyName") == c_name:
            tech_stacks = job.get("techStacks", [])
            tech_stack_list.append(" ".join(tech_stacks))

    # 합쳐서 하나의 문자열로
    company_profile_text = " ".join(tech_stack_list)
    company_profiles[c_name] = company_profile_text.strip()

############################
# 4) 좋아요/싫어요 기업 프로필 사전
############################
# 좋아요/싫어요 기업마다 profile 텍스트를 미리 가져온다.
liked_profiles = [company_profiles[c] for c in liked_companies if c in company_profiles]
disliked_profiles = [company_profiles[c] for c in disliked_companies if c in company_profiles]

############################
# 5) 유사도 계산 함수
############################
def compute_cosine_sim(text_a, text_b):
    """TF-IDF 벡터화 후 코사인 유사도 계산"""
    if not text_a.strip() or not text_b.strip():
        return 0.0
    vectorizer = TfidfVectorizer()
    tfidf = vectorizer.fit_transform([text_a, text_b])
    sim = cosine_similarity(tfidf[0:1], tfidf[1:2])[0][0]
    return sim

def avg(lst):
    """평균 계산, 비어있으면 0 반환"""
    return sum(lst)/len(lst) if lst else 0.0

############################
# 6) 콘텐츠 기반 점수 계산
############################
recommendations = []

for c_name in companies.keys():
    # 6-1) 사용자 vs. 기업 유사도
    user_sim = compute_cosine_sim(user_profile_text, company_profiles[c_name])

    # 6-2) 좋아요 기업과의 유사도
    liked_sims = []
    for lp in liked_profiles:
        liked_sims.append(compute_cosine_sim(company_profiles[c_name], lp))
    avg_liked = avg(liked_sims)

    # 6-3) 싫어요 기업과의 유사도
    disliked_sims = []
    for dp in disliked_profiles:
        disliked_sims.append(compute_cosine_sim(company_profiles[c_name], dp))
    avg_disliked = avg(disliked_sims)

    # 6-4) 최종 점수 = user_sim + ALPHA*avg_liked - BETA*avg_disliked
    final_score = user_sim + ALPHA * avg_liked - BETA * avg_disliked

    # 로고 경로
    logo_filename = companies[c_name].get("logo", "")
    logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""

    recommendations.append({
        "company": c_name,
        "final_score": final_score,
        "logo": logo_path
    })

# 점수 내림차순 정렬
recommendations.sort(key=lambda x: x["final_score"], reverse=True)

############################
# 7) 결과 저장
############################
result_dir = os.path.join(".", "result", username)
os.makedirs(result_dir, exist_ok=True)

timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
result_file = os.path.join(result_dir, f"{timestamp}_content_based_result.json")

with open(result_file, "w", encoding="utf-8") as f:
    json.dump(recommendations, f, ensure_ascii=False, indent=4)

print(f"[콘텐츠 기반 추천] 결과가 {result_file} 에 저장되었습니다.")
