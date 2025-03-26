import os
import json
from glob import glob
import numpy as np
import pandas as pd
from surprise import SVD, Dataset, Reader
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from datetime import datetime

# ─────────────────────────────────────────────────────────────────
# 1. 유저 분석 데이터 로딩 (예시: 유저명이 "chanhoan")
# ─────────────────────────────────────────────────────────────────
username = "chanhoan"
user_folder = f"./user/{username}"
user_files = glob(os.path.join(user_folder, "*.json"))
if not user_files:
    raise Exception(f"유저 분석 JSON 파일이 {user_folder} 내에 존재하지 않습니다.")

with open(user_files[0], "r", encoding="utf-8") as f:
    user_data = json.load(f)

# GitHub 분석 결과에서 각 언어별 커밋 수를 활용해 사용자 프로필 텍스트 생성
user_languages = {}
for lang, metrics in user_data.get("language_commit_metrics", {}).items():
    user_languages[lang] = metrics.get("commit_count", 0)
user_profile_text = " ".join([(lang + " ") * count for lang, count in user_languages.items()])

# ─────────────────────────────────────────────────────────────────
# 2. 공고/기업 정보 로딩
# ─────────────────────────────────────────────────────────────────
job_files = glob("./jobs/*.json")
jobs = []
for job_file in job_files:
    with open(job_file, "r", encoding="utf-8") as f:
        job = json.load(f)
        jobs.append(job)

company_files = glob("./crawling/*.json")
companies = {}
for comp_file in company_files:
    with open(comp_file, "r", encoding="utf-8") as f:
        comp_data = json.load(f)
        company_name = comp_data.get("companyName")
        if company_name:
            companies[company_name] = comp_data

# ─────────────────────────────────────────────────────────────────
# 3. 좋아요/싫어요 목록 (예시) - 실제로는 DB나 사용자 입력으로 관리
# ─────────────────────────────────────────────────────────────────
liked_companies = {}  # 예시: 사용자가 좋아요 누른 기업
disliked_companies = {}                # 예시: 사용자가 싫어요 누른 기업

# ─────────────────────────────────────────────────────────────────
# 4. 상호작용(interaction) 점수 계산 (코사인 유사도)
# ─────────────────────────────────────────────────────────────────
interaction_by_company = {}
vectorizer = TfidfVectorizer()

for job in jobs:
    tech_stacks = job.get("techStacks", [])
    job_profile_text = " ".join(tech_stacks)
    if not job_profile_text.strip():
        continue
    tfidf_matrix = vectorizer.fit_transform([user_profile_text, job_profile_text])
    sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]

    company = job.get("companyName")
    if company:
        interaction_by_company[company] = interaction_by_company.get(company, 0) + sim

# ─────────────────────────────────────────────────────────────────
# 5. 좋아요/싫어요를 반영해 (user, company, rating)을 생성
# ─────────────────────────────────────────────────────────────────
#  - 좋아요 기업 → 5점
#  - 싫어요 기업 → 1점
#  - 나머지 기업 → 코사인 유사도 점수를 0~5 범위로 스케일링
# ----------------------------------------------------------------

data_list = []

# 우선 코사인 유사도 점수의 최댓값을 찾는다 (0~max 범위)
max_sim = max(interaction_by_company.values()) if interaction_by_company else 1.0

for comp in companies.keys():
    # 기본 점수 = 유사도
    base_sim = interaction_by_company.get(comp, 0.0)

    if comp in liked_companies:
        # 좋아요 누른 기업은 최고점
        final_rating = 5.0
    elif comp in disliked_companies:
        # 싫어요 누른 기업은 최저점
        final_rating = 1.0
    else:
        # 0~max_sim 범위를 0~4로 스케일링한 뒤, 1~5 범위를 선호한다면
        # 아래와 같이 해도 되고, 0~5로 직접 스케일링해도 된다.
        scaled_0_5 = (base_sim / max_sim) * 4.0 + 1.0
        final_rating = scaled_0_5

    data_list.append([username, comp, final_rating])

df = pd.DataFrame(data_list, columns=["user", "item", "rating"])

# ─────────────────────────────────────────────────────────────────
# 6. Surprise용 데이터셋 구성 및 모델 학습
# ─────────────────────────────────────────────────────────────────
# rating_scale=(1, 5)로 설정 (싫어요=1점, 좋아요=5점)
reader = Reader(rating_scale=(1, 5))
data_surprise = Dataset.load_from_df(df[["user", "item", "rating"]], reader)
trainset = data_surprise.build_full_trainset()

algo = SVD(n_epochs=20, random_state=42)
algo.fit(trainset)

# ─────────────────────────────────────────────────────────────────
# 7. 예측 및 추천 결과 생성
# ─────────────────────────────────────────────────────────────────
recommendations = []
for comp in companies.keys():
    pred = algo.predict(username, comp)
    adjusted_score = pred.est - 1.0
    logo_filename = companies[comp].get("logo", "")
    logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
    recommendations.append({
        "company": comp,
        "predicted_rating": adjusted_score,
        "logo": logo_path
    })

# 예측 점수가 높은 순으로 정렬
recommendations.sort(key=lambda x: x["predicted_rating"], reverse=True)

# ─────────────────────────────────────────────────────────────────
# 8. 결과 저장
# ─────────────────────────────────────────────────────────────────

result_dir = os.path.join(".", "result", username)
os.makedirs(result_dir, exist_ok=True)

# 날짜-시간 포맷 (예: 20230816-153045)
timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
result_file = os.path.join(result_dir, f"{timestamp}_surprise_result.json")

with open(result_file, "w", encoding="utf-8") as f:
    json.dump(recommendations, f, ensure_ascii=False, indent=4)

print(f"추천 결과가 {result_file} 에 저장되었습니다.")
