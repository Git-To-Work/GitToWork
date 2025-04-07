# app/api/routes/company.py

from fastapi import APIRouter, Depends, Query, HTTPException
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime
from pymongo import MongoClient
import os

from app.core.deps import get_db, get_current_user
from app.models import Company, JobNotice, NoticeTechStack, TechStack, Field, Task
from app.utils.response import success_response

router = APIRouter()


def get_recommended_ids(user_id: str, selected_repositories_id: str) -> List[int]:
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise HTTPException(status_code=500, detail="MongoDB URL not set")
    mongo_client = MongoClient(mongodb_url)
    mongo_db = mongo_client.get_default_database()
    recommend_collection = mongo_db["recommend_result"]
    recommend_doc = recommend_collection.find_one({
        "user_id": user_id,
        "selected_repositories_id": selected_repositories_id
    })
    if not recommend_doc:
        raise HTTPException(status_code=404, detail="No recommendation result found for this user & repository")
    return [rec["company_id"] for rec in recommend_doc.get("recommendations", [])]


def build_company_query(
        db: Session,
        recommended_ids: List[int],
        field: Optional[str],
        career: Optional[int],
        keyword: Optional[str],
        location: Optional[List[str]],
        tech_stacks: Optional[List[str]]
):
    query = db.query(Company).join(JobNotice, JobNotice.company_id == Company.company_id, isouter=True)
    query = query.filter(Company.company_id.in_(recommended_ids)).filter(Company.company_id >= 1)

    if field:
        query = query.join(Task, JobNotice.task).filter(Task.task_name == field)

    if career is not None:
        query = query.filter(
            and_(
                JobNotice.min_career <= career,
                JobNotice.max_career >= career
            )
        )

    if keyword:
        like_pattern = f"%{keyword}%"
        query = query.filter(Company.company_name.ilike(like_pattern))

    if location and len(location) > 0:
        query = query.filter(or_(*[JobNotice.location.ilike(f"%{loc}%") for loc in location if loc]))

    if tech_stacks and len(tech_stacks) > 0:
        query = query.join(
            NoticeTechStack, NoticeTechStack.job_notice_id == JobNotice.job_notice_id, isouter=True
        ).join(
            TechStack, TechStack.tech_stack_id == NoticeTechStack.tech_stack_id, isouter=True
        ).filter(
            TechStack.tech_stack_name.in_(tech_stacks)
        )
    return query


def order_companies(companies: List[Company], recommended_ids: List[int]) -> List[Company]:
    company_map = {company.company_id: company for company in companies}
    return [company_map[cid] for cid in recommended_ids if cid in company_map]


def paginate_companies(companies: List[Company], page: int, size: int) -> Tuple[List[Company], int]:
    total = len(companies)
    start = (page - 1) * size
    end = start + size
    total_page = (total - 1) // size + 1 if total > 0 else 1
    return companies[start:end], total_page


def format_company(company: Company, user_id: str, now: datetime) -> dict:
    # field_name: Company와 연결된 Field에서 추출 (존재하면)
    field_name = company.field.field_name if hasattr(company, "field") and company.field else None

    # scraped 여부: 현재 사용자가 해당 회사를 스크랩했는지 확인
    scraped = any(us.user_id == user_id for us in getattr(company, "user_scraps", []))

    # tech_stacks: 회사의 모든 채용 공고에서 기술 스택 이름 수집
    tech_stack_set = set()
    for job in getattr(company, "job_notices", []):
        for nts in getattr(job, "notice_tech_stacks", []):
            if nts.tech_stack and nts.tech_stack.tech_stack_name:
                tech_stack_set.add(nts.tech_stack.tech_stack_name)
    tech_stack_list = list(tech_stack_set)

    # hasJobNotice: 현재 시각 기준으로 마감 기한이 남은 채용 공고가 있는지 확인
    has_job_notice = any(job.deadline_dttm > now for job in getattr(company, "job_notices", []))

    return {
        "company_id": company.company_id,
        "company_name": company.company_name,
        "logo": company.logo,
        "likes": company.likes,
        "field_id": company.field_id,
        "field_name": field_name,
        "scraped": scraped,
        "tech_stacks": tech_stack_list,
        "hasJobNotice": has_job_notice
    }


@router.get("/select/companies", response_model=dict)
def get_companies(
        selected_repositories_id: str,
        tech_stacks: Optional[List[str]] = Query(None),
        field: Optional[str] = None,
        career: Optional[int] = None,
        keyword: Optional[str] = None,
        location: Optional[List[str]] = Query(None),
        page: int = 1,
        size: int = 20,
        db: Session = Depends(get_db),
        current_user=Depends(get_current_user)
):
    user_id = current_user.user_id

    # 1. 추천 결과 조회
    recommended_ids = get_recommended_ids(user_id, selected_repositories_id)
    if not recommended_ids:
        return success_response({
            "companies": [],
            "total": 0,
            "page": page,
            "size": size,
            "total_page": 0
        }, status_code=200, message="No recommended companies", code="SU")

    # 2. SQLAlchemy 쿼리 구성
    query = build_company_query(db, recommended_ids, field, career, keyword, location, tech_stacks)
    filtered_companies = query.with_entities(Company).distinct(Company.company_id).all()

    # 3. 추천 순서 유지하여 정렬
    ordered_companies = order_companies(filtered_companies, recommended_ids)

    # 4. 페이징 처리
    total = len(ordered_companies)
    page_companies, total_page = paginate_companies(ordered_companies, page, size)

    # 5. 응답 데이터 구성
    now = datetime.now()
    result = [format_company(company, user_id, now) for company in page_companies]

    return success_response(
        {
            "companies": result,
            "total": total,
            "page": page,
            "size": size,
            "total_page": total_page
        },
        status_code=200,
        message="OK",
        code="SU"
    )
