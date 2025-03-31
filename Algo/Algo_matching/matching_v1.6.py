import os
import json
from glob import glob
from datetime import datetime
import numpy as np
import pandas as pd

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from surprise import SVD, Dataset, Reader

#############################################
# 1. 설정 및 사용자 데이터 로딩
#############################################
username = "chanhoan"

# 좋아요/싫어요 기업 (예시)
liked_companies = {"현대자동차"}
disliked_companies = {"에프엘이에스"}

# 하이브리드 가중치 (콘텐츠 vs. CF)
ALPHA = 0.9  
BETA = 0.1  

# 콘텐츠 기반 내 좋아요/싫어요 보정 가중치
LIKE_BONUS = 0.3
DISLIKE_PENALTY = 0.3

# 사용자 GitHub 분석 JSON 로딩
user_folder = f"./user/{username}"
json_files = glob(os.path.join(user_folder, "*.json"))
if not json_files:
    raise FileNotFoundError(f"{user_folder} 내에 사용자 분석 JSON이 없습니다.")
with open(json_files[0], "r", encoding="utf-8") as f:
    user_data = json.load(f)

#############################################
# 2. 사용자 프로필 텍스트 생성 (다중 언어 복잡도 반영)
#############################################
# (A) 기본: 각 언어의 커밋 수 기반 텍스트
user_languages = user_data.get("language_commit_metrics", {})
base_profile_parts = []
for lang, metrics in user_languages.items():
    commit_count = metrics.get("commit_count", 0)
    base_profile_parts.append((lang + " ") * commit_count)
base_profile_text = " ".join(base_profile_parts)

# (B) 다중 언어 복잡도 가중치 적용
# 복잡도 메트릭 로딩 (각 언어별 average_cyclomatic_complexity)
complexity_metrics = user_data.get("complexity_metrics", {})

# 사용자가 사용한 언어 중 복잡도 정보를 가진 언어들의 평균 복잡도 목록
complexity_values = []
for lang in user_languages:
    if lang in complexity_metrics:
        avg_cc = complexity_metrics[lang].get("average_cyclomatic_complexity")
        if avg_cc is not None:
            complexity_values.append(avg_cc)
if complexity_values:
    min_complexity = min(complexity_values)
else:
    min_complexity = 1.0

# 각 언어별 유효 커밋 수 = commit_count * (min_complexity / 해당 언어의 복잡도)
weighted_profile_parts = []
for lang, metrics in user_languages.items():
    commit_count = metrics.get("commit_count", 0)
    avg_cc = complexity_metrics.get(lang, {}).get("average_cyclomatic_complexity", 1.0)
    weight = min_complexity / avg_cc if avg_cc > 0 else 1.0
    effective_commits = max(1, int(round(commit_count * weight)))  # 최소 1회 반복
    weighted_profile_parts.append((lang + " ") * effective_commits)
weighted_profile_text = " ".join(weighted_profile_parts)

# (C) README 분석: Flesch Reading Ease 기준 토큰
readme_analysis = user_data.get("readme_analysis", {})
flesch_score = readme_analysis.get("flesch_reading_ease", 0)
readability_token = "EasyRead" if flesch_score > 70 else "HardRead"

# (D) 최종 사용자 프로필 텍스트: 기본 텍스트 + 가중 텍스트 + 읽기 토큰
user_profile_text = base_profile_text + " " + weighted_profile_text + " " + readability_token
print("개선된 사용자 프로필 텍스트:")
print(user_profile_text)

#############################################
# 3. 공고 및 기업 정보 로딩
#############################################
# 공고 데이터 로딩
job_files = glob("./jobs/*.json")
jobs = []
for job_file in job_files:
    with open(job_file, "r", encoding="utf-8") as f:
        jobs.append(json.load(f))

# 기업 데이터 로딩
company_files = glob("./crawling/*.json")
companies = {}
for comp_file in company_files:
    with open(comp_file, "r", encoding="utf-8") as f:
        comp_data = json.load(f)
        comp_name = comp_data.get("companyName")
        if comp_name:
            companies[comp_name] = comp_data

#############################################
# 4. 기업 프로필 텍스트 생성 (콘텐츠 기반)
#############################################
company_profiles = {}
for comp_name in companies.keys():
    tech_texts = []
    for job in jobs:
        if job.get("companyName") == comp_name:
            tech_texts.append(" ".join(job.get("techStacks", [])))
    company_profiles[comp_name] = " ".join(tech_texts).strip()

#############################################
# 5. 콘텐츠 기반 점수 계산
#############################################
def compute_cosine_sim(text_a, text_b):
    if not text_a.strip() or not text_b.strip():
        return 0.0
    vectorizer = TfidfVectorizer()
    tfidf = vectorizer.fit_transform([text_a, text_b])
    return cosine_similarity(tfidf[0:1], tfidf[1:2])[0][0]

def avg(lst):
    return sum(lst)/len(lst) if lst else 0.0

content_scores = {}
# 미리 좋아요/싫어요 기업 프로필 추출
liked_profiles = [company_profiles[c] for c in liked_companies if c in company_profiles]
disliked_profiles = [company_profiles[c] for c in disliked_companies if c in company_profiles]

for comp_name in companies.keys():
    user_sim = compute_cosine_sim(user_profile_text, company_profiles[comp_name])
    like_sims = [compute_cosine_sim(company_profiles[comp_name], lp) for lp in liked_profiles]
    avg_like = avg(like_sims)
    dislike_sims = [compute_cosine_sim(company_profiles[comp_name], dp) for dp in disliked_profiles]
    avg_dislike = avg(dislike_sims)
    final_content_score = user_sim + LIKE_BONUS * avg_like - DISLIKE_PENALTY * avg_dislike
    content_scores[comp_name] = final_content_score

#############################################
# 6. 협업 필터링 점수 계산 (CF) via Surprise (SVD)
#############################################
interaction_by_company = {}
vectorizer_cf = TfidfVectorizer()
for job in jobs:
    tech_stacks = job.get("techStacks", [])
    job_text = " ".join(tech_stacks)
    if not job_text.strip():
        continue
    tfidf_mat = vectorizer_cf.fit_transform([user_profile_text, job_text])
    sim = cosine_similarity(tfidf_mat[0:1], tfidf_mat[1:2])[0][0]
    comp = job.get("companyName")
    if comp:
        interaction_by_company[comp] = interaction_by_company.get(comp, 0.0) + sim

max_sim = max(interaction_by_company.values()) if interaction_by_company else 1.0

cf_data_list = []
for comp in companies.keys():
    base_sim = interaction_by_company.get(comp, 0.0)
    if comp in liked_companies:
        rating = 5.0
    elif comp in disliked_companies:
        rating = 1.0
    else:
        rating = (base_sim / max_sim) * 4.0 + 1.0
    cf_data_list.append([username, comp, rating])
df_cf = pd.DataFrame(cf_data_list, columns=["user", "item", "rating"])

reader = Reader(rating_scale=(1, 5))
data_surprise = Dataset.load_from_df(df_cf[["user", "item", "rating"]], reader)
trainset = data_surprise.build_full_trainset()

algo = SVD(n_epochs=20, random_state=42)
algo.fit(trainset)

cf_scores = {}
for comp in companies.keys():
    pred = algo.predict(username, comp)
    cf_scores[comp] = pred.est

#############################################
# 7. 점수 정규화 및 하이브리드 결합
#############################################
def min_max_normalize(score_dict):
    values = list(score_dict.values())
    min_val = min(values)
    max_val = max(values)
    if max_val == min_val:
        return {k: 0.0 for k in score_dict}
    return {k: (v - min_val) / (max_val - min_val) for k, v in score_dict.items()}

content_norm = min_max_normalize(content_scores)
cf_norm = min_max_normalize(cf_scores)

final_recommendations = []
for comp in companies.keys():
    norm_content = content_norm.get(comp, 0.0)
    norm_cf = cf_norm.get(comp, 0.0)
    hybrid_score = ALPHA * norm_content + BETA * norm_cf
    logo_filename = companies[comp].get("logo", "")
    logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
    final_recommendations.append({
        "company": comp,
        "content_score_raw": content_scores.get(comp, 0.0),
        "cf_score_raw": cf_scores.get(comp, 0.0),
        "content_score_norm": norm_content,
        "cf_score_norm": norm_cf,
        "hybrid_score": hybrid_score,
        "logo": logo_path
    })

final_recommendations.sort(key=lambda x: x["hybrid_score"], reverse=True)

#############################################
# 8. 결과 저장 (날짜-시간 포함)
#############################################
result_dir = os.path.join(".", "result", username)
os.makedirs(result_dir, exist_ok=True)
timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
result_file = os.path.join(result_dir, f"{timestamp}_hybrid_with_complexity_result.json")

with open(result_file, "w", encoding="utf-8") as f:
    json.dump(final_recommendations, f, ensure_ascii=False, indent=4)

print(f"[하이브리드 추천] 결과가 {result_file} 에 저장되었습니다.")
