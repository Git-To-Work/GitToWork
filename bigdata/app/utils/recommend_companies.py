import json
import os
from datetime import datetime

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sqlalchemy.orm import Session
from surprise import SVD, Dataset, Reader

from app.models import JobNotice, Company

import logging


def min_max_normalize(score_dict):
    values = list(score_dict.values())
    min_val = min(values)
    max_val = max(values)
    if max_val == min_val:
        # 모든 값이 동일할 경우, 정규화하지 않고 원래 값으로 사용
        return {k: v for k, v in score_dict.items()}
    return {k: (v - min_val) / (max_val - min_val) for k, v in score_dict.items()}


def run_hybrid_recommendation(db: Session,
                              user_id,
                              selected_repositories_id,
                              user_github_name,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_detail_history,
                              analysis_result
                              ):
    #############################################
    # 1. 사용자 분석 결과 로딩 및 파싱
    #############################################
    if isinstance(analysis_result, str):
        analysis_result = analysis_result.strip().lstrip('\ufeff')
        try:
            analysis_result = json.loads(analysis_result)
        except json.JSONDecodeError as e:
            raise ValueError(f"JSON 파싱 실패: {e}")

    #############################################
    # 2. 사용자 프로필 텍스트 생성 (여러 저장소 데이터 병합: complexity 및 README 반영)
    #############################################
    repositories = analysis_result.get("repositories", [])
    if not repositories:
        raise ValueError("분석 결과에 저장소 데이터가 없습니다.")

    # 저장소별 language_commit_metrics, complexity_metrics, readme_analysis 병합
    merged_language_metrics = {}
    merged_complexity_metrics = {}
    readme_scores = []

    for repo in repositories:
        # language_commit_metrics 병합 (commit_count 누적)
        repo_lang = repo.get("language_commit_metrics", {})
        for lang, metrics in repo_lang.items():
            commit_count = metrics.get("commit_count", 0)
            if lang in merged_language_metrics:
                merged_language_metrics[lang]["commit_count"] += commit_count
            else:
                merged_language_metrics[lang] = {"commit_count": commit_count}

        # complexity_metrics 병합 (여기서는 값이 존재하면 우선 적용)
        repo_comp = repo.get("complexity_metrics", {})
        for lang, metrics in repo_comp.items():
            # 만약 이미 값이 있다면, 0이 아닌 값이 있다면 업데이트
            if lang in merged_complexity_metrics:
                if metrics.get("average_cyclomatic_complexity", 0) > 0:
                    merged_complexity_metrics[lang] = metrics
            else:
                merged_complexity_metrics[lang] = metrics

        # readme_analysis: Flesch Reading Ease 점수 수집
        readme = repo.get("readme_analysis", {})
        if readme:
            readme_scores.append(readme.get("flesch_reading_ease", 0))

    max_flesch = max(readme_scores) if readme_scores else 0

    # 병합된 데이터를 기반으로 사용자 프로필 텍스트 생성
    user_languages = merged_language_metrics
    complexity_metrics = merged_complexity_metrics

    # 복잡도 값이 0보다 큰 항목만 사용
    complexity_values = []
    for lang in user_languages:
        if lang in complexity_metrics:
            avg_cc = complexity_metrics[lang].get("average_cyclomatic_complexity")
            if avg_cc is not None and avg_cc > 0:
                complexity_values.append(avg_cc)
    min_complexity = min(complexity_values) if complexity_values else 1.0

    weighted_profile_parts = []
    for lang, metrics in user_languages.items():
        commit_count = metrics.get("commit_count", 0)
        avg_cc = complexity_metrics.get(lang, {}).get("average_cyclomatic_complexity", 1.0)
        if avg_cc <= 0:
            avg_cc = 1.0
        weight = min_complexity / avg_cc
        effective_commits = max(1, int(round(commit_count * weight)))
        weighted_profile_parts.append((lang + " ") * effective_commits)
    weighted_profile_text = " ".join(weighted_profile_parts)

    # README 분석: Flesch Reading Ease 기준 토큰 (없으면 기본값 부여)
    readability_token = "EasyRead" if max_flesch > 70 else "HardRead"

    user_profile_text = weighted_profile_text + " " + readability_token

    #############################################
    # 3. DB에서 공고 및 기업 정보 로딩 (기존 로직 사용)
    #############################################
    company_rows = db.query(Company).all()
    companies = {}
    # companies의 key는 회사의 고유 식별자 또는 이름(일관성 필요)
    for comp in company_rows:
        company_id = comp.company_id  # 또는 comp.company_name 등
        companies[company_id] = comp.__dict__

    jobs = db.query(JobNotice).all()

    #############################################
    # 4. 기업별 프로필 텍스트 생성 (콘텐츠 기반)
    #############################################
    # 각 기업에 대해 관련 공고에서 기술 스택을 모아 텍스트 생성
    company_profiles = {}
    for comp in company_rows:  # company_rows는 db.query(Company).all()로 가져온 객체 리스트
        tech_texts = []
        # comp.job_notices는 해당 회사와 연결된 모든 JobNotice 객체를 포함합니다.
        for job in comp.job_notices:
            if hasattr(job, "notice_tech_stacks"):
                tech_stacks = [nts.tech_stack.tech_stack_name
                               for nts in job.notice_tech_stacks
                               if nts.tech_stack and nts.tech_stack.tech_stack_name]
            else:
                tech_stacks = []
            tech_texts.append(" ".join(tech_stacks))
        # 데이터가 없으면 회사 이름을 대체 텍스트로 사용할 수 있음 (빈 문자열 대신)
        profile_text = " ".join(tech_texts).strip() or comp.company_name
        company_profiles[comp.company_id] = profile_text

    #############################################
    # 5. 콘텐츠 기반 점수 계산 (배치 처리)
    #############################################
    company_ids = list(company_profiles.keys())
    company_texts = [company_profiles[c_id] for c_id in company_ids]
    vectorizer_company = TfidfVectorizer()
    # 모든 기업 프로필의 TF-IDF 행렬 계산
    company_tfidf_matrix = vectorizer_company.fit_transform(company_texts)
    # 사용자 프로필 벡터 계산 (동일 벡터라이저 사용)
    user_vector = vectorizer_company.transform([user_profile_text])
    # 사용자와 각 기업 간 유사도 계산
    base_similarities = cosine_similarity(user_vector, company_tfidf_matrix).flatten()

    # 미리 좋아요/블랙리스트 기업의 인덱스 추출
    liked_indices = [company_ids.index(c) for c in liked_companies_set if c in company_ids]
    blacklisted_indices = [company_ids.index(c) for c in blacklisted_companies_set if c in company_ids]

    content_scores = {}
    # 상수: 추가 신호 가중치 (리팩토링된 값 사용)
    LIKED_BONUS = 0.3
    BLACKLISTED_PENALTY = 0.5
    SCRAPED_BONUS = 0.5
    SEARCH_BONUS = 0.1

    for idx, comp_id in enumerate(company_ids):
        base_score = base_similarities[idx]
        # 좋아요 신호
        if liked_indices:
            comp_vector = company_tfidf_matrix[idx]
            liked_vectors = company_tfidf_matrix[liked_indices]
            like_sims = cosine_similarity(comp_vector, liked_vectors).flatten()
            avg_like = np.mean(like_sims)
        else:
            avg_like = 0.0
        # 블랙리스트 신호
        if blacklisted_indices:
            comp_vector = company_tfidf_matrix[idx]
            blacklisted_vectors = company_tfidf_matrix[blacklisted_indices]
            blacklist_sims = cosine_similarity(comp_vector, blacklisted_vectors).flatten()
            avg_blacklisted = np.mean(blacklist_sims)
        else:
            avg_blacklisted = 0.0

        final_content_score = base_score + LIKED_BONUS * avg_like - BLACKLISTED_PENALTY * avg_blacklisted

        # 추가 신호: 스크랩 및 조회
        if comp_id in scraped_companies_set:
            final_content_score += SCRAPED_BONUS
        if comp_id in user_search_detail_history:
            final_content_score += SEARCH_BONUS

        content_scores[comp_id] = final_content_score

    #############################################
    # 6. 협업 필터링 점수 계산 (CF) via Surprise (SVD)
    #############################################
    # 1. 모든 job의 기술 스택 텍스트와 해당 job의 회사 ID를 한 번에 수집
    job_texts = []
    job_company_ids = []
    for job in jobs:
        if hasattr(job, "notice_tech_stacks"):
            tech_stacks = [nts.tech_stack.tech_stack_name for nts in job.notice_tech_stacks
                           if nts.tech_stack and nts.tech_stack.tech_stack_name]
        else:
            tech_stacks = []
        job_text = " ".join(tech_stacks)
        if not job_text.strip():
            continue
        job_texts.append(job_text)
        job_company_ids.append(job.company_id)

    # 2. TfidfVectorizer를 한 번 학습하여 모든 job 텍스트에 대해 벡터 생성
    vectorizer_cf = TfidfVectorizer()
    job_tfidf_matrix = vectorizer_cf.fit_transform(job_texts)

    # 3. 사용자 프로필 텍스트에 대해 동일 벡터라이저를 사용하여 벡터 생성
    user_vector_cf = vectorizer_cf.transform([user_profile_text])

    # 4. 배치로 사용자와 모든 job의 코사인 유사도 계산
    cf_similarities = cosine_similarity(user_vector_cf, job_tfidf_matrix).flatten()

    # 5. 기업별 상호작용 점수 집계: 동일 기업에 속하는 job들의 유사도 합산
    interaction_by_company = {}
    for comp_id, sim in zip(job_company_ids, cf_similarities):
        if comp_id:
            interaction_by_company[comp_id] = interaction_by_company.get(comp_id, 0.0) + sim

    max_sim_cf = max(interaction_by_company.values()) if interaction_by_company else 1.0

    # 6. (user, company, rating) 데이터 구성: 좋아요/블랙리스트 신호 반영
    cf_data_list = []
    for comp_id in companies.keys():
        base_sim = interaction_by_company.get(comp_id, 0.0)
        if comp_id in liked_companies_set:
            rating = 5.0
        elif comp_id in blacklisted_companies_set:
            rating = 1.0
        else:
            rating = (base_sim / max_sim_cf) * 4.0 + 1.0
        cf_data_list.append([user_github_name, comp_id, rating])
    df_cf = pd.DataFrame(cf_data_list, columns=["user", "item", "rating"])

    # 7. Surprise 라이브러리를 이용해 SVD 모델 학습 및 CF 점수 예측
    reader = Reader(rating_scale=(1, 5))
    data_surprise_cf = Dataset.load_from_df(df_cf[["user", "item", "rating"]], reader)
    trainset = data_surprise_cf.build_full_trainset()

    algo = SVD(n_epochs=20, random_state=42)
    algo.fit(trainset)

    cf_scores = {}
    for comp_id in companies.keys():
        pred = algo.predict(user_github_name, comp_id)
        cf_scores[comp_id] = pred.est

    #############################################
    # 7. 점수 정규화 및 하이브리드 결합
    #############################################
    content_norm = min_max_normalize(content_scores)
    cf_norm = min_max_normalize(cf_scores)

    ALPHA = 0.9
    BETA = 0.1

    final_recommendations = []
    for comp_id in companies.keys():
        if comp_id in blacklisted_companies_set:
            continue
        norm_content = content_norm.get(comp_id, 0.0)
        norm_cf = cf_norm.get(comp_id, 0.0)
        hybrid_score = ALPHA * norm_content + BETA * norm_cf
        logo_filename = companies[comp_id].get("logo", "")
        logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
        final_recommendations.append({
            "company_id": comp_id,
            "company_name": companies[comp_id].get("company_name", ""),
            "content_score_raw": content_scores.get(comp_id, 0.0),
            "cf_score_raw": cf_scores.get(comp_id, 0.0),
            "content_score_norm": norm_content,
            "cf_score_norm": norm_cf,
            "hybrid_score": hybrid_score,
            "logo": logo_path
        })

    final_recommendations.sort(key=lambda x: x["hybrid_score"], reverse=True)

    #############################################
    # 8. 결과 저장 (MongoDB에 저장 또는 다른 방식 활용)
    #############################################
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise ValueError("MONGODB_URL 환경 변수가 설정되지 않았습니다.")
    from pymongo import MongoClient
    client = MongoClient(mongodb_url)
    mongo_db = client.get_default_database()
    recommend_collection = mongo_db["recommend_result"]

    record = {
        "user_id": user_id,
        "selected_repositories_id": selected_repositories_id,
        "user_github_name": user_github_name,
        "recommendations": final_recommendations,
        "timestamp": datetime.utcnow().isoformat()
    }

    result = recommend_collection.update_one(
        {"user_id": user_id, "selected_repositories_id": selected_repositories_id},
        {"$set": record},
        upsert=True
    )
    logging.log(logging.INFO, f"[하이브리드 추천] 결과가 MongoDB에 저장(업데이트)되었습니다. user_id : {user_id}, selected_repositories_id : {selected_repositories_id}")
