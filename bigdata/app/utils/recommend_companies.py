import os
import json
from glob import glob
from datetime import datetime
import pandas as pd

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from surprise import SVD, Dataset, Reader


def run_hybrid_recommendation(username,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_history,
                              user_search_detail_history,
                              aggregate_selected_repo_stats_data
                              ):
    #############################################
    # 1. 설정 (사용자, 가중치, 좋아요/싫어요 등)
    #############################################
    # 좋아요 / 싫어요 기업 (예시)
    liked_companies = {"현대자동차"}
    blacklist_companies = {"에프엘이에스"}

    # 하이브리드 가중치
    ALPHA = 0.9  # 콘텐츠 기반 점수 비중
    BETA = 0.1  # 협업 필터링 점수 비중

    # 콘텐츠 기반에서 좋아요 기업 유사도 보너스, 싫어요 기업 유사도 패널티
    LIKE_BONUS = 0.3
    BLACKLIST_PENALTY = 0.3

    ######################################
    # 2. 사용자 GitHub 분석 JSON 로딩
    ######################################

    user_folder = f"../user/{username}"
    print(f"사용자 폴더 경로: {user_folder}")
    print("경로 존재 여부:", os.path.exists(user_folder))

    json_files = glob(os.path.join(user_folder, "*.json"))
    if not json_files:
        raise FileNotFoundError(f"{user_folder} 내에 사용자 분석 JSON이 없습니다.")

    with open(json_files[0], "r", encoding="utf-8") as f:
        user_data = json.load(f)

    # GitHub 언어별 커밋 수 -> 사용자 프로필 텍스트
    user_profile_list = []
    for lang, info in user_data.get("language_commit_metrics", {}).items():
        count = info.get("commit_count", 0)
        user_profile_list.append((lang + " ") * count)
    user_profile_text = " ".join(user_profile_list)

    ######################################
    # 3. 공고 & 기업 정보 로딩
    ######################################
    jobs = []
    for job_file in glob("../data/jobs/*.json"):
        with open(job_file, "r", encoding="utf-8") as f:
            jobs.append(json.load(f))

    companies = {}
    for comp_file in glob("../data/crawling/*.json"):
        with open(comp_file, "r", encoding="utf-8") as f:
            comp_data = json.load(f)
            c_name = comp_data.get("companyName")
            if c_name:
                companies[c_name] = comp_data

    ######################################
    # 4. 기업별 공고 텍스트(콘텐츠) 만들기
    ######################################
    # ex) {"현대자동차": "Python C++ Java ...", "오픈엣지테크놀로지": "Python Go ...", ...}
    company_profiles = {}
    for c_name in companies.keys():
        tech_texts = []
        for job in jobs:
            if job.get("companyName") == c_name:
                tech_stacks = job.get("techStacks", [])
                tech_texts.append(" ".join(tech_stacks))
        company_profiles[c_name] = " ".join(tech_texts).strip()

    ######################################
    # 5. 콘텐츠 기반 점수 계산
    ######################################
    def compute_cosine_sim(text_a, text_b):
        if not text_a.strip() or not text_b.strip():
            return 0.0
        vec = TfidfVectorizer()
        tfidf = vec.fit_transform([text_a, text_b])
        return cosine_similarity(tfidf[0:1], tfidf[1:2])[0][0]

    def avg(values):
        return sum(values) / len(values) if values else 0.0

    # 좋아요/싫어요 기업 프로필
    liked_profiles = [company_profiles[c] for c in liked_companies if c in company_profiles]
    blacklist_profiles = [company_profiles[c] for c in blacklist_companies if c in company_profiles]

    content_scores = {}  # {회사명: 콘텐츠 기반 점수}
    for c_name in companies.keys():
        # 사용자 vs. 기업 유사도
        user_sim = compute_cosine_sim(user_profile_text, company_profiles[c_name])

        # 좋아요 기업과의 유사도 평균
        like_sims = []
        for lp in liked_profiles:
            like_sims.append(compute_cosine_sim(company_profiles[c_name], lp))
        avg_like = avg(like_sims)

        # 싫어요 기업과의 유사도 평균
        blacklist_sims = []
        for dp in blacklist_profiles:
            blacklist_sims.append(compute_cosine_sim(company_profiles[c_name], dp))
        avg_blacklist = avg(blacklist_sims)

        # 최종 콘텐츠 점수
        final_content_score = user_sim + LIKE_BONUS * avg_like - BLACKLIST_PENALTY * avg_blacklist
        content_scores[c_name] = final_content_score

    ######################################
    # 6. 협업 필터링(SVD) 점수 계산
    ######################################
    # 6-1) TF-IDF 유사도 기반 점수 → 1~5로 스케일링 + 좋아요=5, 싫어요=1
    interaction_by_company = {}

    # 사용자 vs 공고 TF-IDF
    vec2 = TfidfVectorizer()
    for job in jobs:
        tech_stacks = job.get("techStacks", [])
        job_text = " ".join(tech_stacks)
        if not job_text.strip():
            continue
        tfidf_mat = vec2.fit_transform([user_profile_text, job_text])
        sim = cosine_similarity(tfidf_mat[0:1], tfidf_mat[1:2])[0][0]
        c_name = job.get("companyName")
        if c_name:
            interaction_by_company[c_name] = interaction_by_company.get(c_name, 0.0) + sim

    max_sim = max(interaction_by_company.values()) if interaction_by_company else 1.0

    data_list = []
    for c_name in companies.keys():
        base_sim = interaction_by_company.get(c_name, 0.0)

        if c_name in liked_companies:
            rating = 5.0
        elif c_name in blacklist_companies:
            rating = 1.0
        else:
            # 0~max_sim -> 1~5 스케일링
            rating = (base_sim / max_sim) * 4.0 + 1.0

        data_list.append([username, c_name, rating])

    df_cf = pd.DataFrame(data_list, columns=["user", "item", "rating"])

    reader = Reader(rating_scale=(1, 5))
    data_surprise = Dataset.load_from_df(df_cf[["user", "item", "rating"]], reader)
    trainset = data_surprise.build_full_trainset()

    algo = SVD(n_epochs=20, random_state=42)
    algo.fit(trainset)

    cf_scores = {}  # {회사명: CF 예측 점수}
    for c_name in companies.keys():
        pred = algo.predict(username, c_name)
        cf_scores[c_name] = pred.est

    ######################################
    # 7. 점수 정규화(선택) & 하이브리드 결합
    ######################################
    def min_max_normalize(score_dict):
        vals = list(score_dict.values())
        min_v = min(vals)
        max_v = max(vals)
        if max_v == min_v:
            return {k: 0.0 for k in score_dict}
        normed = {}
        for k, v in score_dict.items():
            normed[k] = (v - min_v) / (max_v - min_v)
        return normed

    content_norm = min_max_normalize(content_scores)
    cf_norm = min_max_normalize(cf_scores)

    final_recommendations = []
    for c_name in companies.keys():
        c_score = content_norm[c_name]
        cf_score = cf_norm[c_name]
        hybrid_score = ALPHA * c_score + BETA * cf_score
        logo_filename = companies[c_name].get("logo", "")
        logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
        final_recommendations.append({
            "company": c_name,
            "content_score_raw": content_scores[c_name],
            "cf_score_raw": cf_scores[c_name],
            "content_score_norm": c_score,
            "cf_score_norm": cf_score,
            "hybrid_score": hybrid_score,
            "logo": logo_path
        })

    # 점수 내림차순 정렬
    final_recommendations.sort(key=lambda x: x["hybrid_score"], reverse=True)

    ######################################
    # 8. 결과 저장
    ######################################
    result_dir = os.path.join(".", "result", username)
    os.makedirs(result_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    result_file = os.path.join(result_dir, f"{timestamp}_hybrid_result.json")

    with open(result_file, "w", encoding="utf-8") as f:
        json.dump(final_recommendations, f, ensure_ascii=False, indent=4)

    print(f"[하이브리드 추천] 결과가 {result_file} 에 저장되었습니다.")


# 예시: 다른 코드에서 이 함수를 호출할 때
if __name__ == "__main__":
    user_input = input("사용자 이름을 입력하세요: ")
    run_hybrid_recommendation(user_input)
