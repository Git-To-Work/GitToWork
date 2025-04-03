# app/api/routes/recommendation.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.utils.git_analyze import run_full_analysis
from app.utils.mongo_logger import get_user_search_history
from app.utils.recommend_companies import run_hybrid_recommendation
from app.utils.response import success_response_only_message

router = APIRouter()

@router.get("/recommendation", response_model=dict)
def get_recommendation(
        selected_repositories_id: str,
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    try:
        user_id = current_user.user_id
        user_github_name = current_user.github_name

        # 현재 사용자 객체(User 모델)에서 GitHub access token 추출
        user_github_access_token = current_user.github_access_token
        if not user_github_access_token:
            raise HTTPException(status_code=401, detail="GitHub access token not available")

        # 분석 함수 실행: run_full_analysis는 분석 결과를 JSON 문자열로 반환
        analysis_result = run_full_analysis(user_github_access_token, selected_repositories_id)

        # 현재 사용자가 좋아요, 스크랩, 블랙리스트한 기업들을 set으로 구성
        liked_companies_set = {ul.company.company_id for ul in current_user.user_likes}
        blacklisted_companies_set = {ub.company.company_id for ub in current_user.user_blacklists}
        scraped_companies_set = {us.company.company_id for us in current_user.user_scraps}

        # MongoDB에서 사용자 검색 로그 가져오기
        user_search_detail_history = get_user_search_history(user_id, "user_search_detail_history")

        run_hybrid_recommendation(
            db,
            user_id,  # user_id
            selected_repositories_id,  # selected_repositories_id
            user_github_name,  # username
            liked_companies_set,
            blacklisted_companies_set,
            scraped_companies_set,
            user_search_detail_history,
            analysis_result  # analysis_result
        )

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Analysis failed: {str(e)}")

    return success_response_only_message(
        status_code=200,
        message="Analysis completed",
        code="SU"
    )
