import os
import json
from glob import glob
import numpy as np
import pandas as pd
from surprise import SVD, Dataset, Reader
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# 1. 유저 분석 데이터 로딩 (예시: 유저명이 "chanhoan")
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

# 2. 공고 데이터 로딩 (./jobs 내 모든 JSON 파일)
job_files = glob("./jobs/*.json")
jobs = []
for job_file in job_files:
    with open(job_file, "r", encoding="utf-8") as f:
        job = json.load(f)
        jobs.append(job)

# 3. 기업 정보 데이터 로딩 (./crawling 내 모든 JSON 파일)
company_files = glob("./crawling/*.json")
companies = {}
for comp_file in company_files:
    with open(comp_file, "r", encoding="utf-8") as f:
         comp_data = json.load(f)
         company_name = comp_data.get("companyName")
         if company_name:
              companies[company_name] = comp_data

# 4. 상호작용(interaction) 점수 계산
# 각 공고의 기술 스택을 문자열로 결합하고, 사용자 프로필 텍스트와의 코사인 유사도를 계산하여
# 해당 공고의 소속 기업에 점수를 누적합니다.
interaction_by_company = {}
vectorizer = TfidfVectorizer()
for job in jobs:
    tech_stacks = job.get("techStacks", [])
    job_profile_text = " ".join(tech_stacks)
    if not job_profile_text.strip():
         continue
    # TF-IDF 벡터 생성 및 코사인 유사도 계산
    tfidf_matrix = vectorizer.fit_transform([user_profile_text, job_profile_text])
    sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
    company = job.get("companyName")
    if company:
         interaction_by_company[company] = interaction_by_company.get(company, 0) + sim

# 5. Surprise를 위한 데이터 준비
# (user, company, rating) 형태의 데이터를 구성합니다.
data_list = []
for company in companies.keys():
    rating = interaction_by_company.get(company, 0)  # 해당 기업에 대한 누적 유사도 점수
    data_list.append([username, company, rating])
df = pd.DataFrame(data_list, columns=["user", "item", "rating"])

# Surprise의 Reader는 rating scale을 필요로 합니다.
max_rating = df["rating"].max() if df["rating"].max() > 0 else 1.0
reader = Reader(rating_scale=(0, max_rating))
data_surprise = Dataset.load_from_df(df[["user", "item", "rating"]], reader)
trainset = data_surprise.build_full_trainset()

# 6. Surprise 추천 모델(SVD) 학습
algo = SVD(n_epochs=20, random_state=42)
algo.fit(trainset)

# 7. 각 기업에 대한 예측 점수 산출 및 추천 결과 구성
recommendations = []
for company in companies.keys():
    pred = algo.predict(username, company)
    logo_filename = companies[company].get("logo", "")
    logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
    recommendations.append({
         "company": company,
         "predicted_rating": pred.est,
         "logo": logo_path
    })

# 예측 점수가 높은 순으로 정렬
recommendations = sorted(recommendations, key=lambda x: x["predicted_rating"], reverse=True)

# 8. 결과 파일 저장: ./result/{username}/surprise_result.json
result_dir = os.path.join(".", "result", username)
os.makedirs(result_dir, exist_ok=True)
result_file = os.path.join(result_dir, "surprise_result.json")
with open(result_file, "w", encoding="utf-8") as f:
    json.dump(recommendations, f, ensure_ascii=False, indent=4)

print(f"추천 결과가 {result_file} 에 저장되었습니다.")
