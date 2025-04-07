import json
import os
import logging
from datetime import datetime
from zoneinfo import ZoneInfo

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sqlalchemy.orm import Session
from surprise import SVD, Dataset, Reader

from app.models import JobNotice, Company

# 현재 시각 (UTC 및 KST)
now_utc = datetime.now(tz=ZoneInfo("UTC"))
now_kst = now_utc.astimezone(ZoneInfo("Asia/Seoul")).isoformat()


def min_max_normalize(score_dict):
    values = list(score_dict.values())
    min_val = min(values)
    max_val = max(values)
    if max_val == min_val:
        return {k: v for k, v in score_dict.items()}
    return {k: (v - min_val) / (max_val - min_val) for k, v in score_dict.items()}


def parse_analysis_result(analysis_result):
    """사용자 분석 결과를 JSON 객체로 파싱합니다."""
    if isinstance(analysis_result, str):
        analysis_result = analysis_result.strip().lstrip('\ufeff')
        try:
            return json.loads(analysis_result)
        except json.JSONDecodeError as e:
            raise ValueError(f"JSON 파싱 실패: {e}")
    return analysis_result


# --- merge_repository_metrics 관련 헬퍼 함수 ---
def _merge_language_commit_metrics(repositories):
    merged = {}
    for repo in repositories:
        repo_lang = repo.get("language_commit_metrics", {})
        for lang, metrics in repo_lang.items():
            commit_count = metrics.get("commit_count", 0)
            if lang in merged:
                merged[lang]["commit_count"] += commit_count
            else:
                merged[lang] = {"commit_count": commit_count}
    return merged


def _merge_complexity_metrics(repositories):
    merged = {}
    for repo in repositories:
        repo_comp = repo.get("complexity_metrics", {})
        for lang, metrics in repo_comp.items():
            # 복잡도 값이 0보다 큰 경우 우선 적용
            if lang in merged:
                if metrics.get("average_cyclomatic_complexity", 0) > 0:
                    merged[lang] = metrics
            else:
                merged[lang] = metrics
    return merged


def _max_readme_flesch(repositories):
    readme_scores = []
    for repo in repositories:
        readme = repo.get("readme_analysis", {})
        if readme:
            readme_scores.append(readme.get("flesch_reading_ease", 0))
    return max(readme_scores) if readme_scores else 0


def merge_repository_metrics(repositories):
    """
    각 저장소의 language_commit_metrics, complexity_metrics, readme_analysis 데이터를 병합합니다.
    반환: (merged_language_metrics, merged_complexity_metrics, max_flesch)
    """
    merged_language_metrics = _merge_language_commit_metrics(repositories)
    merged_complexity_metrics = _merge_complexity_metrics(repositories)
    max_flesch = _max_readme_flesch(repositories)
    return merged_language_metrics, merged_complexity_metrics, max_flesch


def create_user_profile_text(merged_lang, merged_comp, max_flesch):
    """병합된 데이터를 기반으로 사용자 프로필 텍스트를 생성합니다."""
    user_languages = merged_lang
    complexity_metrics = merged_comp
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
    readability_token = "EasyRead" if max_flesch > 70 else "HardRead"
    return weighted_profile_text + " " + readability_token


def load_data_from_db(db: Session):
    """DB에서 회사 및 채용 공고 데이터를 로딩합니다."""
    company_rows = db.query(Company).all()
    jobs = db.query(JobNotice).all()
    companies = {comp.company_id: comp.__dict__ for comp in company_rows}
    return company_rows, companies, jobs


def generate_company_profiles(company_rows):
    """
    각 회사의 관련 공고(기술 스택 정보)를 모아 콘텐츠 기반 프로필 텍스트를 생성합니다.
    """
    profiles = {}
    for comp in company_rows:
        tech_texts = []
        for job in getattr(comp, "job_notices", []):
            if hasattr(job, "notice_tech_stacks"):
                tech_stacks = [nts.tech_stack.tech_stack_name
                               for nts in job.notice_tech_stacks
                               if nts.tech_stack and nts.tech_stack.tech_stack_name]
            else:
                tech_stacks = []
            tech_texts.append(" ".join(tech_stacks))
        profile_text = " ".join(tech_texts).strip() or comp.company_name
        profiles[comp.company_id] = profile_text
    return profiles


def compute_content_scores(company_profiles, user_profile_text, liked_set, blacklisted_set, scraped_set,
                           search_history):
    """콘텐츠 기반 점수를 계산합니다."""
    vectorizer = TfidfVectorizer()
    company_ids = list(company_profiles.keys())
    company_texts = [company_profiles[cid] for cid in company_ids]
    company_tfidf = vectorizer.fit_transform(company_texts)
    user_vector = vectorizer.transform([user_profile_text])
    base_sims = cosine_similarity(user_vector, company_tfidf).flatten()

    # 상수 가중치
    LIKED_BONUS = 0.3
    BLACKLISTED_PENALTY = 0.5
    SCRAPED_BONUS = 0.5
    SEARCH_BONUS = 0.1

    liked_indices = [company_ids.index(c) for c in liked_set if c in company_ids]
    blacklisted_indices = [company_ids.index(c) for c in blacklisted_set if c in company_ids]

    content_scores = {}
    for idx, comp_id in enumerate(company_ids):
        base_score = base_sims[idx]
        avg_like = (np.mean(cosine_similarity(company_tfidf[idx], company_tfidf[liked_indices]).flatten())
                    if liked_indices else 0.0)
        avg_black = (np.mean(cosine_similarity(company_tfidf[idx], company_tfidf[blacklisted_indices]).flatten())
                     if blacklisted_indices else 0.0)
        score = base_score + LIKED_BONUS * avg_like - BLACKLISTED_PENALTY * avg_black
        if comp_id in scraped_set:
            score += SCRAPED_BONUS
        if comp_id in search_history:
            score += SEARCH_BONUS
        content_scores[comp_id] = score
    return content_scores, company_ids


# --- compute_cf_scores 관련 헬퍼 함수 ---
def _extract_job_texts_and_ids(jobs):
    job_texts, job_company_ids = [], []
    for job in jobs:
        if hasattr(job, "notice_tech_stacks"):
            tech_stacks = [nts.tech_stack.tech_stack_name for nts in job.notice_tech_stacks
                           if nts.tech_stack and nts.tech_stack.tech_stack_name]
        else:
            tech_stacks = []
        text = " ".join(tech_stacks)
        if not text.strip():
            continue
        job_texts.append(text)
        job_company_ids.append(job.company_id)
    return job_texts, job_company_ids


def compute_cf_scores(companies, jobs, user_profile_text, user_github_name, liked_set, blacklisted_set):
    """협업 필터링(CF) 점수를 Surprise 라이브러리를 사용하여 계산합니다."""
    job_texts, job_company_ids = _extract_job_texts_and_ids(jobs)
    if not job_texts:
        return {}
    vectorizer_cf = TfidfVectorizer()
    job_tfidf = vectorizer_cf.fit_transform(job_texts)
    user_vector_cf = vectorizer_cf.transform([user_profile_text])
    cf_sims = cosine_similarity(user_vector_cf, job_tfidf).flatten()

    interaction = {}
    for comp_id, sim in zip(job_company_ids, cf_sims):
        if comp_id:
            interaction[comp_id] = interaction.get(comp_id, 0.0) + sim
    max_sim = max(interaction.values()) if interaction else 1.0

    cf_data = []
    for comp_id in companies.keys():
        base_sim = interaction.get(comp_id, 0.0)
        if comp_id in liked_set:
            rating = 5.0
        elif comp_id in blacklisted_set:
            rating = 1.0
        else:
            rating = (base_sim / max_sim) * 4.0 + 1.0
        cf_data.append([user_github_name, comp_id, rating])
    df_cf = pd.DataFrame(cf_data, columns=["user", "item", "rating"])
    reader = Reader(rating_scale=(1, 5))
    data = Dataset.load_from_df(df_cf[["user", "item", "rating"]], reader)
    trainset = data.build_full_trainset()
    algo = SVD(n_epochs=20, random_state=42)
    algo.fit(trainset)
    cf_scores = {}
    for comp_id in companies.keys():
        pred = algo.predict(user_github_name, comp_id)
        cf_scores[comp_id] = pred.est
    return cf_scores


def combine_scores(companies, content_scores, cf_scores, blacklisted_set):
    """
    정규화 후 콘텐츠 및 CF 점수를 하이브리드로 결합하고 추천 리스트를 생성합니다.
    사용하지 않는 매개변수(liked_set, company_ids)를 제거하였습니다.
    """
    content_norm = min_max_normalize(content_scores)
    cf_norm = min_max_normalize(cf_scores)
    ALPHA, BETA = 0.9, 0.1
    recommendations = []
    for comp_id in companies.keys():
        if comp_id in blacklisted_set:
            continue
        hybrid = ALPHA * content_norm.get(comp_id, 0.0) + BETA * cf_norm.get(comp_id, 0.0)
        logo = companies[comp_id].get("logo", "")
        logo_path = os.path.join("./crawling_img", logo) if logo else ""
        recommendations.append({
            "company_id": comp_id,
            "company_name": companies[comp_id].get("company_name", ""),
            "content_score_raw": content_scores.get(comp_id, 0.0),
            "cf_score_raw": cf_scores.get(comp_id, 0.0),
            "content_score_norm": content_norm.get(comp_id, 0.0),
            "cf_score_norm": cf_norm.get(comp_id, 0.0),
            "hybrid_score": hybrid,
            "logo": logo_path
        })
    recommendations.sort(key=lambda x: x["hybrid_score"], reverse=True)
    return recommendations


def save_to_mongo(user_id, selected_repositories_id, user_github_name, recommendations, now_kst):
    """최종 추천 결과를 MongoDB에 저장합니다."""
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise ValueError("MONGODB_URL 환경 변수가 설정되지 않았습니다.")
    from pymongo import MongoClient
    client = MongoClient(mongodb_url)
    mongo_db = client.get_default_database()
    rec_collection = mongo_db["recommend_result"]
    record = {
        "user_id": user_id,
        "selected_repositories_id": selected_repositories_id,
        "user_github_name": user_github_name,
        "recommendations": recommendations,
        "timestamp": now_kst
    }
    rec_collection.update_one(
        {"user_id": user_id, "selected_repositories_id": selected_repositories_id},
        {"$set": record},
        upsert=True
    )
    logging.log(logging.INFO,
                f"[하이브리드 추천] 결과가 MongoDB에 저장(업데이트)되었습니다. user_id : {user_id}, selected_repositories_id : {selected_repositories_id}")


# --- 메인 함수 ---
def run_hybrid_recommendation(db: Session,
                              user_id,
                              selected_repositories_id,
                              user_github_name,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_detail_history,
                              analysis_result):
    # 1. 분석 결과 파싱 및 사용자 프로필 텍스트 생성
    analysis_result = parse_analysis_result(analysis_result)
    repositories = analysis_result.get("repositories", [])
    if not repositories:
        raise ValueError("분석 결과에 저장소 데이터가 없습니다.")
    merged_lang, merged_comp, max_flesch = merge_repository_metrics(repositories)
    user_profile_text = create_user_profile_text(merged_lang, merged_comp, max_flesch)

    # 2. DB에서 회사 및 채용 공고 데이터 로딩
    company_rows, companies, jobs = load_data_from_db(db)
    company_profiles = generate_company_profiles(company_rows)

    # 3. 콘텐츠 기반 점수 계산
    content_scores, _ = compute_content_scores(
        company_profiles, user_profile_text, liked_companies_set,
        blacklisted_companies_set, scraped_companies_set, user_search_detail_history
    )

    # 4. 협업 필터링 점수 계산
    cf_scores = compute_cf_scores(companies, jobs, user_profile_text, user_github_name,
                                  liked_companies_set, blacklisted_companies_set)

    # 5. 하이브리드 점수 결합 및 추천 리스트 생성
    final_recommendations = combine_scores(companies, content_scores, cf_scores,
                                           blacklisted_companies_set)

    # 6. 추천 결과를 MongoDB에 저장
    save_to_mongo(user_id, selected_repositories_id, user_github_name, final_recommendations, now_kst)
