# app/api/routes/company.py

from fastapi import APIRouter
from typing import List, Optional
from fastapi import Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime
from pymongo import MongoClient
import os

from app.core.deps import get_db, get_current_user
from app.models import Company, JobNotice, NoticeTechStack, TechStack, Field
from app.utils.response import success_response

router = APIRouter()
@router.get("/select/companies", response_model=dict)
def get_companies(
        selected_repositories_id: str,
        tech_stacks: Optional[List[str]] = Query(None),
        field: Optional[str] = None,  # 필드 조건 (예: field_name substring)
        career: Optional[int] = None,  # 경력 조건
        keyword: Optional[str] = None,  # 회사명 또는 채용 공고 제목에 포함된 키워드
        location: Optional[List[str]] = Query(None),  # 지역 배열 조건
        page: int = 1,
        size: int = 20,
        db: Session = Depends(get_db),
        current_user=Depends(get_current_user)
):
    user_id = current_user.user_id

    # 1. MongoDB: 추천 결과 조회 (user_id + selected_repositories_id 기준)
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

    # 추천 순서대로 회사 ID 목록 추출
    recommended_ids = [rec["company_id"] for rec in recommend_doc.get("recommendations", [])]
    if not recommended_ids:
        return success_response({
            "companies": [],
            "total": 0,
            "page": page,
            "size": size,
            "total_page": 0
        }, status_code=200, message="No recommended companies", code="SU")

    # 2. SQLAlchemy: 추천 결과에 포함된 회사들 조회 (JOIN JobNotice for 추가 필터)
    query = db.query(Company).join(JobNotice, JobNotice.company_id == Company.company_id, isouter=True)
    query = query.filter(Company.company_id.in_(recommended_ids))

    # (a) field 필터: Company.field 관계를 활용하여 Field.field_name을 직접 참조
    if field:
        query = query.filter(Company.field.has(Field.field_name.ilike(f"%{field}%")))

    # (b) career 필터: 채용 공고의 min_career, max_career 조건
    if career is not None:
        query = query.filter(
            and_(
                JobNotice.min_career <= career,
                JobNotice.max_career >= career
            )
        )

    # (c) keyword 필터: 회사명 또는 채용 공고 제목에 keyword 포함
    if keyword:
        like_pattern = f"%{keyword}%"
        query = query.filter(
            or_(
                Company.company_name.ilike(like_pattern),
                JobNotice.job_notice_title.ilike(like_pattern)
            )
        )

    # (d) location 필터: 입력된 지역 배열 중 하나라도 JobNotice.location과 일치
    if location and len(location) > 0:
        query = query.filter(
            or_(*[JobNotice.location.ilike(f"%{loc}%") for loc in location])
        )

    # (e) techstacks 필터: JOIN NoticeTechStack와 TechStack, tech_stack_name이 techstacks에 포함
    if tech_stacks and len(tech_stacks) > 0:
        query = query.join(
            NoticeTechStack, NoticeTechStack.job_notice_id == JobNotice.job_notice_id, isouter=True
        ).join(
            TechStack, TechStack.tech_stack_id == NoticeTechStack.tech_stack_id, isouter=True
        ).filter(
            TechStack.tech_stack_name.in_(tech_stacks)
        )

    # 중복 제거
    query = query.distinct(Company.company_id)
    filtered_companies = query.all()

    # 3. 추천 순서 유지: 추천 결과에서 가져온 순서대로 재정렬
    company_map = {company.company_id: company for company in filtered_companies}
    ordered_companies = [company_map[cid] for cid in recommended_ids if cid in company_map]

    # 4. 페이징 처리
    total = len(ordered_companies)
    start = (page - 1) * size
    end = start + size
    page_companies = ordered_companies[start:end]
    total_page = (total - 1) // size + 1 if total > 0 else 1

    # 5. 응답 데이터 구성
    result = []
    now = datetime.now()
    for company in page_companies:
        # field_name: Company.field 관계에서 추출 (있을 경우)
        field_name = company.field.field_name if hasattr(company, "field") and company.field else None

        # scraped 여부: 현재 사용자가 해당 회사를 스크랩했는지 (user_scraps 관계)
        scraped = False
        if user_id and hasattr(company, "user_scraps"):
            scraped = any(us.user_id == user_id for us in company.user_scraps)

        # techstacks: 회사의 모든 채용 공고에서 NoticeTechStack을 순회하여 기술 스택 이름 수집
        tech_stack_set = set()
        if hasattr(company, "job_notices"):
            for job in company.job_notices:
                if hasattr(job, "notice_tech_stacks"):
                    for nts in job.notice_tech_stacks:
                        if nts.tech_stack and nts.tech_stack.tech_stack_name:
                            tech_stack_set.add(nts.tech_stack.tech_stack_name)
        tech_stack_list = list(tech_stack_set)

        # hasJobNotice: 현재 시각 기준으로, deadline_dttm이 남은 채용 공고가 있는지 확인
        has_job_notice = False
        if hasattr(company, "job_notices"):
            has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)

        result.append({
            "company_id": company.company_id,
            "company_name": company.company_name,
            "logo": company.logo,
            "likes": company.likes,
            "field_id": company.field_id,
            "field_name": field_name,
            "scraped": scraped,
            "tech_stacks": tech_stack_list,
            "hasJobNotice": has_job_notice
        })

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