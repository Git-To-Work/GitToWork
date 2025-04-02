import os
from datetime import datetime
import pandas as pd
from pymongo import MongoClient

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from surprise import SVD, Dataset, Reader

from app.models import JobNotice, Company

def run_hybrid_recommendation(db,
                              user_id,
                              selected_repositories_id,
                              username,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_detail_history,
                              analysis_result
                              ):
    #############################################
    # 1. 설정 (사용자, 가중치, 좋아요/싫어요 등)
    #############################################

    # 하이브리드 가중치
    ALPHA = 0.9  # 콘텐츠 기반 점수 비중
    BETA = 0.1   # 협업 필터링 점수 비중

    # 콘텐츠 기반 내 추가 신호 가중치
    LIKE_BONUS = 0.3
    BLACKLIST_PENALTY = 0.3
    SCRAPED_BONUS = 0.5  # 구독: 큰 긍정

    SEARCH_BONUS = 0.1   # 조회: 작은 긍정

    ######################################
    # 2. 사용자 GitHub 분석 JSON 로딩
    ######################################

    user_data = analysis_result

    # GitHub 언어별 커밋 수 -> 사용자 프로필 텍스트
    user_profile_list = []
    for lang, info in user_data.get("language_commit_metrics", {}).items():
        count = info.get("commit_count", 0)
        user_profile_list.append((lang + " ") * count)
    user_profile_text = " ".join(user_profile_list)

    ######################################
    # 3. 공고 & 기업 정보 로딩
    ######################################

    # company 테이블에서 기업 정보 가져오기 (key를 company_id로)
    company_rows = db.query(Company).all()
    companies = {}
    for comp in company_rows:
        company_id = comp.company_id
        companies[company_id] = comp.__dict__

    jobs = db.query(JobNotice).all()

    ######################################
    # 4. 기업별 공고 텍스트(콘텐츠) 만들기
    ######################################
    # 예: {101: "Python C++ Java ...", 102: "Python Go ...", ...}
    company_profiles = {}
    for company_id in companies.keys():
        tech_texts = []
        for job in jobs:
            # job에서 회사 ID를 사용하여 비교
            if job.get("company_id") == company_id:
                tech_stacks = job.get("techStacks", [])
                tech_texts.append(" ".join(tech_stacks))
        company_profiles[company_id] = " ".join(tech_texts).strip()

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

    # 좋아요/싫어요 기업 프로필 (liked_companies_set, blacklisted_companies_set는 이제 company_id)
    liked_profiles = [company_profiles[c_id] for c_id in liked_companies_set if c_id in company_profiles]
    blacklist_profiles = [company_profiles[c_id] for c_id in blacklisted_companies_set if c_id in company_profiles]

    content_scores = {}  # {회사_id: 콘텐츠 기반 점수}
    for company_id in companies.keys():
        # 사용자 vs. 기업 유사도
        user_sim = compute_cosine_sim(user_profile_text, company_profiles[company_id])

        # 좋아요 기업과의 유사도 평균
        like_sims = [compute_cosine_sim(company_profiles[company_id], lp) for lp in liked_profiles]
        avg_like = avg(like_sims)

        # 싫어요 기업과의 유사도 평균
        blacklist_sims = [compute_cosine_sim(company_profiles[company_id], dp) for dp in blacklist_profiles]
        avg_blacklist = avg(blacklist_sims)

        # 최종 콘텐츠 점수
        final_content_score = user_sim + LIKE_BONUS * avg_like - BLACKLIST_PENALTY * avg_blacklist
        content_scores[company_id] = final_content_score

    ######################################
    # 6. 협업 필터링(SVD) 점수 계산
    ######################################
    # 6-1) TF-IDF 유사도 기반 점수 → 1~5 스케일링 (좋아요:5, 싫어요:1)
    interaction_by_company = {}

    # 사용자 vs. 공고 TF-IDF (회사 ID 기준)
    vec2 = TfidfVectorizer()
    for job in jobs:
        tech_stacks = job.get("techStacks", [])
        job_text = " ".join(tech_stacks)
        if not job_text.strip():
            continue
        tfidf_mat = vec2.fit_transform([user_profile_text, job_text])
        sim = cosine_similarity(tfidf_mat[0:1], tfidf_mat[1:2])[0][0]
        c_id = job.get("company_id")
        if c_id:
            interaction_by_company[c_id] = interaction_by_company.get(c_id, 0.0) + sim

    max_sim = max(interaction_by_company.values()) if interaction_by_company else 1.0

    data_list = []
    for company_id in companies.keys():
        base_sim = interaction_by_company.get(company_id, 0.0)

        if company_id in liked_companies_set:
            rating = 5.0
        elif company_id in blacklisted_companies_set:
            rating = 1.0
        else:
            # 0~max_sim -> 1~5 스케일링
            rating = (base_sim / max_sim) * 4.0 + 1.0

        data_list.append([username, company_id, rating])

    df_cf = pd.DataFrame(data_list, columns=["user", "item", "rating"])

    reader = Reader(rating_scale=(1, 5))
    data_surprise = Dataset.load_from_df(df_cf[["user", "item", "rating"]], reader)
    trainset = data_surprise.build_full_trainset()

    algo = SVD(n_epochs=20, random_state=42)
    algo.fit(trainset)

    cf_scores = {}  # {회사_id: CF 예측 점수}
    for company_id in companies.keys():
        pred = algo.predict(username, company_id)
        cf_scores[company_id] = pred.est

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
    for company_id in companies.keys():
        c_score = content_norm[company_id]
        cf_score = cf_norm[company_id]
        hybrid_score = ALPHA * c_score + BETA * cf_score
        logo_filename = companies[company_id].get("logo", "")
        logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
        final_recommendations.append({
            "company_id": company_id,
            "company_name": companies[company_id].get("company_name", ""),
            "content_score_raw": content_scores[company_id],
            "cf_score_raw": cf_scores[company_id],
            "content_score_norm": c_score,
            "cf_score_norm": cf_score,
            "hybrid_score": hybrid_score,
            "logo": logo_path
        })

    # 점수 내림차순 정렬
    final_recommendations.sort(key=lambda x: x["hybrid_score"], reverse=True)

    ######################################
    # 8. 결과 저장 (MongoDB에 저장)
    ######################################
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise ValueError("MONGODB_URL 환경 변수가 설정되지 않았습니다.")
    client = MongoClient(mongodb_url)
    mongo_db = client.get_default_database()
    recommend_collection = mongo_db["recommend_result"]

    record = {
        "user_id": user_id,
        "selected_repositories_id": selected_repositories_id,
        "username": username,
        "recommendations": final_recommendations,
        "timestamp": datetime.utcnow().isoformat()
    }

    # 동일한 user_id와 selected_repositories_id를 기준으로 문서를 업데이트(업서트)
    result = recommend_collection.update_one(
        {"user_id": user_id, "selected_repositories_id": selected_repositories_id},
        {"$set": record},
        upsert=True
    )
    print(f"[하이브리드 추천] 결과가 MongoDB에 저장(업데이트)되었습니다. result: {result.raw_result}")
