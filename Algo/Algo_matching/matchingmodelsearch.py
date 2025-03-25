import os
import json
from glob import glob
import numpy as np
import pandas as pd

from surprise import SVD, SVDpp, NMF, KNNBasic, KNNWithMeans, KNNBaseline, CoClustering
from surprise import Dataset, Reader

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def load_user_profile(username):
    """
    ./user/{username} 폴더 내 JSON 파일 중 하나를 로드해,
    사용자 프로필 텍스트를 생성해 반환한다.
    """
    user_folder = f"./user/{username}"
    user_files = glob(os.path.join(user_folder, "*.json"))
    if not user_files:
        raise Exception(f"유저 분석 JSON 파일이 {user_folder} 내에 존재하지 않습니다.")
    with open(user_files[0], "r", encoding="utf-8") as f:
        user_data = json.load(f)

    # GitHub 분석 결과에서 언어별 커밋 수를 텍스트로 변환
    user_languages = {}
    for lang, metrics in user_data.get("language_commit_metrics", {}).items():
        user_languages[lang] = metrics.get("commit_count", 0)
    user_profile_text = " ".join([(lang + " ") * count for lang, count in user_languages.items()])
    return user_profile_text

def load_jobs():
    """ ./jobs/*.json 로딩 """
    job_files = glob("./jobs/*.json")
    jobs = []
    for job_file in job_files:
        with open(job_file, "r", encoding="utf-8") as f:
            job = json.load(f)
            jobs.append(job)
    return jobs

def load_companies():
    """ ./crawling/*.json 로딩 """
    company_files = glob("./crawling/*.json")
    companies = {}
    for comp_file in company_files:
        with open(comp_file, "r", encoding="utf-8") as f:
             comp_data = json.load(f)
             company_name = comp_data.get("companyName")
             if company_name:
                  companies[company_name] = comp_data
    return companies

def build_interaction_scores(user_profile_text, jobs):
    """
    TF-IDF + 코사인 유사도를 통해 (기업: 누적 점수)를 계산해 반환한다.
    """
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

    return interaction_by_company

def prepare_surprise_data(username, companies, interaction_by_company):
    """
    (user, company, rating) 형태의 DataFrame을 만들고,
    Surprise Dataset 객체로 변환하여 반환한다.
    """
    data_list = []
    for comp in companies.keys():
        rating = interaction_by_company.get(comp, 0)
        data_list.append([username, comp, rating])

    df = pd.DataFrame(data_list, columns=["user", "item", "rating"])
    max_rating = df["rating"].max() if df["rating"].max() > 0 else 1.0
    reader = Reader(rating_scale=(0, max_rating))
    data_surprise = Dataset.load_from_df(df[["user", "item", "rating"]], reader)
    return df, data_surprise

def main():
    username = "chanhoan"  # 예시 사용자
    user_profile_text = load_user_profile(username)
    jobs = load_jobs()
    companies = load_companies()

    # 1) 사용자-공고 유사도 기반 상호작용 점수 계산
    interaction_by_company = build_interaction_scores(user_profile_text, jobs)

    # 2) Surprise Dataset 준비
    df_interactions, data_surprise = prepare_surprise_data(username, companies, interaction_by_company)
    trainset = data_surprise.build_full_trainset()

    # 3) 여러 알고리즘 정의
    algorithms = {
        "SVD": SVD(n_epochs=15, random_state=42),
        "SVD++": SVDpp(n_epochs=15, random_state=42),
        "NMF": NMF(n_epochs=15, random_state=42),
        "KNNBasic": KNNBasic(),
        "KNNWithMeans": KNNWithMeans(),
        "KNNBaseline": KNNBaseline(),
        "CoClustering": CoClustering(n_cltr_u=3, n_cltr_i=3, n_epochs=15, random_state=42)
    }

    # 4) 각 알고리즘 학습 & 예측
    all_results = {}  # { 알고리즘명: [ {company, pred_score}, ... ] }

    for algo_name, algo in algorithms.items():
        # 학습
        algo.fit(trainset)

        # 예측
        algo_results = []
        for comp_name in companies.keys():
            pred = algo.predict(username, comp_name)
            score = pred.est
            # 로고 경로
            logo_filename = companies[comp_name].get("logo", "")
            logo_path = os.path.join("./crawling_img", logo_filename) if logo_filename else ""
            algo_results.append({
                "company": comp_name,
                "predicted_rating": score,
                "logo": logo_path
            })

        # 점수 내림차순 정렬
        algo_results.sort(key=lambda x: x["predicted_rating"], reverse=True)
        all_results[algo_name] = algo_results

    # 5) 결과를 각각 JSON으로 저장
    result_dir = os.path.join(".", "result", username)
    os.makedirs(result_dir, exist_ok=True)

    for algo_name, res_list in all_results.items():
        result_file = os.path.join(result_dir, f"surprise_result_{algo_name}.json")
        with open(result_file, "w", encoding="utf-8") as f:
            json.dump(res_list, f, ensure_ascii=False, indent=4)
        print(f"[{algo_name}] 추천 결과가 {result_file} 에 저장되었습니다.")

    # 6) 알고리즘별 상위 10개 기업 비교 (간단 예시)
    print("\n=== 알고리즘별 상위 10개 기업 ===")
    for algo_name, res_list in all_results.items():
        top10 = [r["company"] for r in res_list[:10]]
        print(f"{algo_name} Top10:", top10)

if __name__ == "__main__":
    main()
