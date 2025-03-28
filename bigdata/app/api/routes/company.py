# app/api/routes/company.py

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.deps import get_db, get_current_user
from app.services.company_service import search_companies
from app.utils.response import success_response
from app.utils.mongo_logger import log_user_search

router = APIRouter()


@router.get("/select/companies", response_model=dict)
def get_companies(
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db),
        company_name: Optional[str] = None,
        tech_stacks: Optional[List[str]] = Query(None),
        business_field: Optional[str] = None,
        career: Optional[int] = None,
        location: Optional[str] = None,
        keyword: Optional[str] = None,
        page: int = 1,
        size: int = 20
):
    try:
        user_id = current_user.user_id if hasattr(current_user, "user_id") else current_user.get("user_id")

        # 구성: 검색 필터(페이지, size 제외)
        search_filters = {
            "company_name": company_name,
            "tech_stacks": tech_stacks,
            "business_field": business_field,
            "career": career,
            "location": location,
            "keyword": keyword
        }
        search_filters = {k: v for k, v in search_filters.items() if v is not None}

        log_user_search(user_id, search_filters)

        companies, total_count = search_companies(
            db=db,
            user_id=user_id,
            company_name=company_name,
            tech_stacks=tech_stacks,
            business_field=business_field,
            career=career,
            location=location,
            keyword=keyword,
            page=page,
            size=size
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail="Bad Request")

    result = []
    now = datetime.now()
    for company in companies:
        field_name = company.field.field_name if company.field else None
        categories = []
        if company.field and hasattr(company.field, "categories"):
            categories = [
                {"category_id": cat.category_id, "category_name": cat.category_name}
                for cat in company.field.categories
            ]
        scraped = False
        if user_id and hasattr(company, "user_scraps"):
            scraped = any(us.user_id == user_id for us in company.user_scraps)
        tech_stack_set = set()
        if hasattr(company, "job_notices"):
            for job in company.job_notices:
                if hasattr(job, "notice_tech_stacks"):
                    for nts in job.notice_tech_stacks:
                        if nts.tech_stack:
                            tech_stack_set.add(nts.tech_stack.tech_stack_name)
        tech_stack_list = list(tech_stack_set)
        has_job_notice = False
        if hasattr(company, "job_notices"):
            has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)

        company_data = {
            "company_id": company.company_id,
            "company_name": company.company_name,
            "logo": company.logo,
            "likes": company.likes,
            "field_id": company.field_id,
            "field_name": field_name,
            "categories": categories,
            "scraped": scraped,
            "tech_stacks": tech_stack_list,
            "has_job_notice": has_job_notice
        }
        result.append(company_data)

    total_page = (total_count - 1) // size + 1
    return success_response({
        "companies": result,
        "total": total_count,
        "page": page,
        "size": size,
        "total_page": total_page
    }, status_code=200, message="OK", code="SU")


# app/api/routes/company.py

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.deps import get_db, get_current_user
from app.services.company_service import search_companies
from app.utils.response import success_response
from app.utils.mongo_logger import log_user_search, get_user_search_history

from app.utils.get_git_stat import aggregate_selected_repo_stats
from app.utils.recommend_companies import run_hybrid_recommendation


@router.get("/select/companies_with_algorithm", response_model=dict)
def get_companies_with_algorithm(
        selected_repositories_id: str,
        current_user = Depends(get_current_user),
        db: Session = Depends(get_db),
        company_name: Optional[str] = None,
        tech_stacks: Optional[List[str]] = Query(None),
        business_field: Optional[str] = None,
        career: Optional[int] = None,
        location: Optional[str] = None,
        keyword: Optional[str] = None,
        page: int = 1,
        size: int = 20
):
    try:
        # current_user는 User 객체이므로 바로 속성 접근
        user_id = current_user.user_id
        user_github_name = current_user.github_name

        # 구성: 검색 필터 (페이지, size 제외)
        search_filters = {
            "company_name": company_name,
            "tech_stacks": tech_stacks,
            "business_field": business_field,
            "career": career,
            "location": location,
            "keyword": keyword
        }
        search_filters = {k: v for k, v in search_filters.items() if v is not None}

        # 검색 필터가 있을 경우 MongoDB에 사용자 검색 로그 저장
        if search_filters:
            log_user_search(user_id, search_filters)

        companies, total_count = search_companies(
            db=db,
            user_id=user_id,
            company_name=company_name,
            tech_stacks=tech_stacks,
            business_field=business_field,
            career=career,
            location=location,
            keyword=keyword,
            page=page,
            size=size
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail="Bad Request")

    # 현재 사용자가 좋아요, 스크랩, 블랙리스트한 기업들을 set으로 구성
    liked_companies_set = {ul.company.company_name for ul in current_user.user_likes} if current_user.user_likes else set()
    blacklisted_companies_set = {ub.company.company_name for ub in current_user.user_blacklists} if current_user.user_blacklists else set()
    scraped_companies_set = {us.company.company_name for us in current_user.user_scraps} if current_user.user_scraps else set()

    # MongoDB에서 사용자 검색 로그 가져오기
    user_search_history = get_user_search_history(user_id, "user_search_history")
    user_search_detail_history = get_user_search_history(user_id, "user_search_detail_history")

    #git_hub analysis 가져오기
    aggregate_selected_repo_stats_data = aggregate_selected_repo_stats(selected_repositories_id, user_id)

    # sonarqube data 대체 임시 데이터
    data_example = {
        "language_commit_metrics": {
            "Python": {
                "commit_count": 106
            },
            "Git 설정": {
                "commit_count": 3
            },
            "JavaScript": {
                "commit_count": 7
            },
            "Java": {
                "commit_count": 37
            }
        },
        "complexity_metrics": {
            "Python": {
                "total_files": 106,
                "total_cyclomatic_complexity": 418.33014478985064,
                "total_nloc": 17686,
                "total_token_count": 198473,
                "total_parameter_count": 1175,
                "average_cyclomatic_complexity": 3.95,
                "average_nloc": 166.85,
                "average_token_count": 1872.39,
                "average_parameter_count": 11.08
            },
            "Git 설정": {
                "total_files": 3,
                "total_cyclomatic_complexity": 0.0,
                "total_nloc": 61,
                "total_token_count": 224,
                "total_parameter_count": 0,
                "average_cyclomatic_complexity": 0.0,
                "average_nloc": 20.33,
                "average_token_count": 74.67,
                "average_parameter_count": 0.0
            },
            "JavaScript": {
                "total_files": 7,
                "total_cyclomatic_complexity": 25.55,
                "total_nloc": 418,
                "total_token_count": 3044,
                "total_parameter_count": 6,
                "average_cyclomatic_complexity": 3.65,
                "average_nloc": 59.71,
                "average_token_count": 434.86,
                "average_parameter_count": 0.86
            },
            "Java": {
                "total_files": 37,
                "total_cyclomatic_complexity": 34.62488328664799,
                "total_nloc": 1440,
                "total_token_count": 10935,
                "total_parameter_count": 89,
                "average_cyclomatic_complexity": 0.94,
                "average_nloc": 38.92,
                "average_token_count": 295.54,
                "average_parameter_count": 2.41
            }
        },
        "readme_analysis": {
            "word_count": 194,
            "content_preview": (
                "![poster](./증명사진.png)\n"
                "### 정 찬 환 / 빅데이터 분석 및 AI 개발자\n"
                "***\n"
                "### 개발\n"
                "- 규칙기반 HVAC 시스템 고장진단 알고리즘 개발 [Rule_based_FDD]"
                "(https://github.com/chanhoan/chanhoan_Github/tree/main/Rule_Based_FDD)\n"
                "- 건물 시뮬레이션 데이터 활용 PV(태"
            ),
            "flesch_reading_ease": 83.18
        }
    }

    run_hybrid_recommendation(db,
                              user_github_name,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_history,
                              user_search_detail_history,
                              aggregate_selected_repo_stats_data,
                              data_example)

    # now = datetime.now()
    # for company in companies:
    #     field_name = company.field.field_name if company.field else None
    #     categories = []
    #     if company.field and hasattr(company.field, "categories"):
    #         categories = [
    #             {"category_id": cat.category_id, "category_name": cat.category_name}
    #             for cat in company.field.categories
    #         ]
    #     # 사용자와 연결된 상태는 미리 구성한 set을 이용하여 판단
    #     scraped = company.company_name in scraped_companies_set
    #     liked = company.company_name in liked_companies_set
    #     blacklisted = company.company_name in blacklisted_companies_set
    #
    #     tech_stack_set = set()
    #     if hasattr(company, "job_notices"):
    #         for job in company.job_notices:
    #             if hasattr(job, "notice_tech_stacks"):
    #                 for nts in job.notice_tech_stacks:
    #                     if nts.tech_stack:
    #                         tech_stack_set.add(nts.tech_stack.tech_stack_name)
    #     tech_stack_list = list(tech_stack_set)
    #     has_job_notice = False
    #     if hasattr(company, "job_notices"):
    #         has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)
    #
    #     company_data = {
    #         "company_id": company.company_id,
    #         "company_name": company.company_name,
    #         "logo": company.logo,
    #         "likes": company.likes,
    #         "field_id": company.field_id,
    #         "field_name": field_name,
    #         "categories": categories,
    #         "scraped": scraped,
    #         "liked": liked,
    #         "blacklisted": blacklisted,
    #         "tech_stacks": tech_stack_list,
    #         "has_job_notice": has_job_notice
    #     }
    #     result.append(company_data)
    #
    # total_page = (total_count - 1) // size + 1
    # return success_response({
    #     "companies": result,
    #     "total": total_count,
    #     "page": page,
    #     "size": size,
    #     "total_page": total_page,
    #     "user_search_history": user_search_history
    # }, status_code=200, message="OK", code="SU")
