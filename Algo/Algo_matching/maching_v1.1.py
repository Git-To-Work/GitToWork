import os
import json
from glob import glob
import numpy as np
import pandas as pd
from surprise import SVD, Dataset, Reader
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# (1) CSV에서 기업 점수 로딩
company_scores = pd.read_csv("company_scores2.csv", encoding="cp949")  # companyName, score 컬럼
# 예: companyName,score
#     에스케이하이닉스,82.76
#     삼성전자,82.66
#     ...
company_score_dict = dict(zip(company_scores["companyName"], company_scores["score"]))

# (2) 사용자 정보, 공고, 기업 JSON 로딩 (이전 예제와 동일)
username = "chanhoan"
user_folder = f"./user/{username}"
user_files = glob(os.path.join(user_folder, "*.json"))
with open(user_files[0], "r", encoding="utf-8") as f:
    user_data = json.load(f)

# GitHub 분석 결과 -> 사용자 프로필 텍스트
user_languages = {}
for lang, metrics in user_data.get("language_commit_metrics", {}).items():
    user_languages[lang] = metrics.get("commit_count", 0)
user_profile_text = " ".join([(lang + " ") * count for lang, count in user_languages.items()])

# 공고 정보 로딩
job_files = glob("./jobs/*.json")
jobs = []
for job_file in job_files:
    with open(job_file, "r", encoding="utf-8") as f:
        job = json.load(f)
        jobs.append(job)

# 기업 정보 로딩
company_files = glob("./crawling/*.json")
companies = {}
for comp_file in company_files:
    with open(comp_file, "r", encoding="utf-8") as f:
        comp_data = json.load(f)
        c_name = comp_data.get("companyName")
        if c_name:
            companies[c_name] = comp_data

# (3) TF-IDF 유사도 계산 -> 기업별 누적 점수
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

# (4) 가중 합으로 최종 평점 산출
# 예: alpha=0.7, beta=0.3
alpha = 0.7
beta = 0.3

data_list = []
for c_name in companies.keys():
    # 유사도 점수(0~N) 중 최대 1로 보려면 보통 0~1 범위가 되지만, 누적될 수 있으므로
    # 여기서는 그대로 사용하거나 적절히 스케일링할 수 있음
    similarity_score = interaction_by_company.get(c_name, 0)
    
    # 기업 점수 (0~100)을 0~1로 스케일링
    company_score = company_score_dict.get(c_name, 0) / 100.0
    
    final_rating = alpha * similarity_score + beta * company_score
    data_list.append([username, c_name, final_rating])

df = pd.DataFrame(data_list, columns=["user", "item", "rating"])

# Surprise용 데이터셋
max_rating = df["rating"].max()
reader = Reader(rating_scale=(0, max_rating))
data_surprise = Dataset.load_from_df(df[["user", "item", "rating"]], reader)
trainset = data_surprise.build_full_trainset()

# (5) Surprise SVD 모델 학습
algo = SVD(n_epochs=20, random_state=42)
algo.fit(trainset)

# (6) 예측 결과
recommendations = []
for c_name in companies.keys():
    pred = algo.predict(username, c_name)
    logo_filename = companies[c_name].get("logo", "")
    logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
    recommendations.append({
        "company": c_name,
        "predicted_rating": pred.est,
        "logo": logo_path
    })

# 정렬
recommendations.sort(key=lambda x: x["predicted_rating"], reverse=True)

# 결과 저장
result_dir = os.path.join(".", "result", username)
os.makedirs(result_dir, exist_ok=True)
result_file = os.path.join(result_dir, "surprise_result_with_companyscore.json")
with open(result_file, "w", encoding="utf-8") as f:
    json.dump(recommendations, f, ensure_ascii=False, indent=4)

print(f"결과가 {result_file} 에 저장되었습니다.")
