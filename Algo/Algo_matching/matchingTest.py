import os
import json
import pandas as pd
from glob import glob
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# 1. 회사 점수 로드
company_scores = pd.read_csv("company_scores2.csv", encoding="cp949")  # companyName, score
company_score_dict = dict(zip(company_scores["companyName"], company_scores["score"]))

# 2. 사용자 GitHub 분석 -> 사용자 프로필 텍스트 생성
username = "chanhoan"
user_folder = f"./user/{username}"
user_files = glob(os.path.join(user_folder, "*.json"))
with open(user_files[0], "r", encoding="utf-8") as f:
    user_data = json.load(f)

user_languages = {}
for lang, metrics in user_data.get("language_commit_metrics", {}).items():
    user_languages[lang] = metrics.get("commit_count", 0)
user_profile_text = " ".join([(lang + " ") * count for lang, count in user_languages.items()])

# 3. 공고/기업 데이터 로딩
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
        c_name = comp_data.get("companyName")
        if c_name:
            companies[c_name] = comp_data

# 4. 시나리오 1: 유사도 점수 계산
interaction_by_company = {}
vectorizer = TfidfVectorizer()
for job in jobs:
    tech_stacks = job.get("techStacks", [])
    job_profile_text = " ".join(tech_stacks)
    if not job_profile_text.strip():
        continue
    tfidf_matrix = vectorizer.fit_transform([user_profile_text, job_profile_text])
    sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
    c_name = job.get("companyName")
    if c_name:
        interaction_by_company[c_name] = interaction_by_company.get(c_name, 0) + sim

# 5. 시나리오 2: 기업 점수 (CSV)
# 이미 company_score_dict 에 {회사명: 0~100} 형태로 저장됨

# 6. 각각의 시나리오에 대한 랭킹 비교
data_list = []
for c_name in companies.keys():
    sim_score = interaction_by_company.get(c_name, 0)  # 유사도 누적
    comp_score = company_score_dict.get(c_name, 0)     # 기업 지표 (0~100)

    data_list.append({
        "company": c_name,
        "similarity_score": sim_score,
        "company_score": comp_score
    })

df = pd.DataFrame(data_list)

# 각각 내림차순 순위 구하기
df["rank_similarity"] = df["similarity_score"].rank(method="dense", ascending=False)
df["rank_company"] = df["company_score"].rank(method="dense", ascending=False)

# 순위 차이 계산
df["rank_diff"] = df["rank_company"] - df["rank_similarity"]

# 보기 편하게 정렬
df = df.sort_values(by="similarity_score", ascending=False).reset_index(drop=True)

print(df[["company", "similarity_score", "rank_similarity", 
          "company_score", "rank_company", "rank_diff"]].head(20))

# 필요하다면 결과를 CSV/JSON으로 저장
df.to_csv("compare_scenario.csv", index=False, encoding="utf-8-sig")
