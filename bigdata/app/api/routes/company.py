# # app/api/routes/company.py
#
# from typing import List, Optional
# from fastapi import APIRouter, Depends, Query, HTTPException
# from sqlalchemy.orm import Session
# from datetime import datetime
# from app.core.deps import get_db, get_current_user
# from app.services.company_service import search_companies
# from app.utils.response import success_response
# from app.utils.mongo_logger import log_user_search
#
# router = APIRouter()
#
#
# @router.get("/select/companies", response_model=dict)
# def read_companies(
#         current_user=Depends(get_current_user),
#         db: Session = Depends(get_db),
#         company_name: Optional[str] = None,
#         tech_stacks: Optional[List[str]] = Query(None),
#         business_field: Optional[str] = None,
#         career: Optional[int] = None,
#         location: Optional[str] = None,
#         keyword: Optional[str] = None,
#         page: int = 1,
#         size: int = 20
# ):
#     try:
#         user_id = current_user.user_id if hasattr(current_user, "user_id") else current_user.get("user_id")
#
#         # 구성: 검색 필터(페이지, size 제외)
#         search_filters = {
#             "company_name": company_name,
#             "tech_stacks": tech_stacks,
#             "business_field": business_field,
#             "career": career,
#             "location": location,
#             "keyword": keyword
#         }
#         search_filters = {k: v for k, v in search_filters.items() if v is not None}
#
#         log_user_search(user_id, search_filters)
#
#         companies, total_count = search_companies(
#             db=db,
#             user_id=user_id,
#             company_name=company_name,
#             tech_stacks=tech_stacks,
#             business_field=business_field,
#             career=career,
#             location=location,
#             keyword=keyword,
#             page=page,
#             size=size
#         )
#     except Exception as e:
#         raise HTTPException(status_code=400, detail="Bad Request")
#
#     result = []
#     now = datetime.now()
#     for company in companies:
#         field_name = company.field.field_name if company.field else None
#         categories = []
#         if company.field and hasattr(company.field, "categories"):
#             categories = [
#                 {"category_id": cat.category_id, "category_name": cat.category_name}
#                 for cat in company.field.categories
#             ]
#         scraped = False
#         if user_id and hasattr(company, "user_scraps"):
#             scraped = any(us.user_id == user_id for us in company.user_scraps)
#         tech_stack_set = set()
#         if hasattr(company, "job_notices"):
#             for job in company.job_notices:
#                 if hasattr(job, "notice_tech_stacks"):
#                     for nts in job.notice_tech_stacks:
#                         if nts.tech_stack:
#                             tech_stack_set.add(nts.tech_stack.tech_stack_name)
#         tech_stack_list = list(tech_stack_set)
#         has_job_notice = False
#         if hasattr(company, "job_notices"):
#             has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)
#
#         company_data = {
#             "company_id": company.company_id,
#             "company_name": company.company_name,
#             "logo": company.logo,
#             "likes": company.likes,
#             "field_id": company.field_id,
#             "field_name": field_name,
#             "categories": categories,
#             "scraped": scraped,
#             "tech_stacks": tech_stack_list,
#             "has_job_notice": has_job_notice
#         }
#         result.append(company_data)
#
#     total_page = (total_count - 1) // size + 1
#     return success_response({
#         "companies": result,
#         "total": total_count,
#         "page": page,
#         "size": size,
#         "total_page": total_page
#     }, status_code=200, message="OK", code="SU")
#

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

router = APIRouter()

@router.get("/select/companies", response_model=dict)
def read_companies(
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
        # 사용자와 연결된 상태는 미리 구성한 set을 이용하여 판단
        scraped = company.company_name in scraped_companies_set
        liked = company.company_name in liked_companies_set
        blacklisted = company.company_name in blacklisted_companies_set

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
            "liked": liked,
            "blacklisted": blacklisted,
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
        "total_page": total_page,
        "user_search_history": user_search_history
    }, status_code=200, message="OK", code="SU")
