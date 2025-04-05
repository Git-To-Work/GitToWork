# app/api/routes/recommendation.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.utils.git_analyze import run_full_analysis
from app.utils.mongo_logger import get_user_search_history, get_github_analysis_result_for_recommend
from app.utils.recommend_companies import run_hybrid_recommendation
from app.utils.response import success_response_only_message
from app.core.mongo import get_mongo_db

router = APIRouter()
@router.get("/recommendation/analyze", response_model=dict)
def get_recommendation_analyze(
        selected_repositories_id: str,
        current_user=Depends(get_current_user),
):

    try:
        user_github_access_token = current_user.github_access_token
        if not user_github_access_token:
            raise HTTPException(status_code=401, detail="GitHub access token not available")

        run_full_analysis(user_github_access_token, selected_repositories_id, user_id=current_user.user_id)

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Analysis failed: {str(e)}")

    return success_response_only_message(
        status_code=200,
        message="Analysis completed",
        code="SU"
    )

@router.get("/recommendation", response_model=dict)
def get_recommendation(
        # 기존 파라미터 selected_repositories_id는 더 이상 단일 값으로 사용하지 않음
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    try:
        user_id = current_user.user_id
        user_github_name = current_user.github_name

        # MongoDB에서 github_analysis_result_for_recommend 컬렉션에서 user_id에 해당하는 모든 문서를 조회
        mongo_db = get_mongo_db()
        analysis_collection = mongo_db["github_analysis_result_for_recommend"]

        analysis_docs = list(analysis_collection.find({"user_id": user_id}, {"selected_repositories_id": 1}))
        if not analysis_docs:
            raise HTTPException(status_code=404, detail="No GitHub analysis result found for this user")

        selected_repositories_ids = {doc.get("selected_repositories_id") for doc in analysis_docs if
                             doc.get("selected_repositories_id")}

        # 현재 사용자가 좋아요, 스크랩, 블랙리스트한 기업들을 set으로 구성
        liked_companies_set = {ul.company.company_id for ul in current_user.user_likes}
        blacklisted_companies_set = {ub.company.company_id for ub in current_user.user_blacklists}
        scraped_companies_set = {us.company.company_id for us in current_user.user_scraps}

        # MongoDB에서 사용자 검색 로그 가져오기
        user_search_detail_history = get_user_search_history(user_id, "user_search_detail_history")

        # 각 분석 결과 문서에서 selected_repositories_id와 analysis_result를 추출하여 추천 함수 호출
        for selected_repositories_id in selected_repositories_ids:
            github_analysis_result_for_recommend = get_github_analysis_result_for_recommend(user_id, selected_repositories_id)
            if not github_analysis_result_for_recommend:
                continue

            run_hybrid_recommendation(
                db,
                user_id,
                selected_repositories_id,
                user_github_name,
                liked_companies_set,
                blacklisted_companies_set,
                scraped_companies_set,
                user_search_detail_history,
                github_analysis_result_for_recommend
            )

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Analysis failed: {str(e)}")

    return success_response_only_message(
        status_code=200,
        message="Analysis completed for all repositories",
        code="SU"
    )
