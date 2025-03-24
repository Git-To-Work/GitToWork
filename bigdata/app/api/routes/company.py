# app/api/routes/company.py

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.deps import get_db
from app.services.company_service import search_companies
from app.models.company import Company


router = APIRouter()

@router.get("/select/companies", response_model=dict)
def read_companies(
    db: Session = Depends(get_db),
    user_id: Optional[int] = None,
    company_name: Optional[str] = None,
    tech_stacks: Optional[List[str]] = Query(None),
    business_field: Optional[str] = None,
    career: Optional[int] = None,
    location: Optional[str] = None,
    keyword: Optional[str] = None,
    page: int = 1,
    size: int = 20
):
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

    result = []
    now = datetime.now()
    for company in companies:
        # Field 정보: 연결된 Field 객체에서 field_name 추출
        field_name = company.field.field_name if company.field else None

        # Category 정보: Field와 연결된 Category 목록 추출
        categories = []
        if company.field and hasattr(company.field, "categories"):
            categories = [
                {"category_id": cat.category_id, "category_name": cat.category_name}
                for cat in company.field.categories
            ]

        # scraped: user_id가 주어졌을 경우, 회사의 user_scraps 관계를 통해 스크랩 여부 판단
        scraped = False
        if user_id and hasattr(company, "user_scraps"):
            scraped = any(us.user_id == user_id for us in company.user_scraps)

        # tech_stacks: 모든 채용 공고(JobNotice)에서 연결된 기술 스택 이름을 집합으로 모으기 (마감일 상관없이)
        tech_stack_set = set()
        if hasattr(company, "job_notices"):
            for job in company.job_notices:
                if hasattr(job, "notice_tech_stacks"):
                    for nts in job.notice_tech_stacks:
                        if nts.tech_stack:
                            tech_stack_set.add(nts.tech_stack.tech_stack_name)
        tech_stack_list = list(tech_stack_set)

        # has_job_notice: 현재 시각 이후 마감하는 채용 공고가 있는지 판단 (유효한 채용 공고 여부)
        has_job_notice = False
        if hasattr(company, "job_notices"):
            has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)

        # 반환할 회사 데이터 구성 (불필요한 수치형 필드는 제외)
        company_data = {
            "company_id": company.company_id,
            "company_name": company.company_name,
            "logo": company.logo,
            "likes" : company.likes,
            "field_id": company.field_id,
            "field_name": field_name,
            "categories": categories,
            "scraped": scraped,
            "tech_stacks": tech_stack_list,
            "has_job_notice": has_job_notice
        }
        result.append(company_data)

    total_pages = (total_count - 1) // size + 1
    return {
        "companies": result,
        "total": total_count,
        "page": page,
        "size": size,
        "total_pages": total_pages
    }


@router.get("/select/company/{company_id}", response_model=dict)
def read_company_detail(
        company_id: int,
        user_id: Optional[int] = None,
        db: Session = Depends(get_db)
):
    # 회사 상세 정보 조회
    company = db.query(Company).filter(Company.company_id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    now = datetime.now()

    # Field 정보: 연결된 Field 객체에서 field_name 추출
    field_name = company.field.field_name if company.field else None

    # Category 정보: Field와 연결된 Category 목록 추출
    categories = []
    if company.field and hasattr(company.field, "categories"):
        categories = [
            {"category_id": cat.category_id, "category_name": cat.category_name}
            for cat in company.field.categories
        ]

    # scraped: user_id가 주어졌을 경우, 회사의 user_scraps 관계를 통해 스크랩 여부 판단
    scraped = False
    if user_id and hasattr(company, "user_scraps"):
        scraped = any(us.user_id == user_id for us in company.user_scraps)

    # liked: user_id가 주어졌을 경우, 회사의 user_likes 관계를 통해 좋아요 여부 판단
    liked = False
    if user_id and hasattr(company, "user_likes"):
        liked = any(ul.user_id == user_id for ul in company.user_likes)

    # blacklisted: user_id가 주어졌을 경우, 회사의 user_blacklists 관계를 통해 블랙리스트 여부 판단
    blacklisted = False
    if user_id and hasattr(company, "user_blacklists"):
        blacklisted = any(ub.user_id == user_id for ub in company.user_blacklists)

    # tech_stacks: 모든 채용 공고(JobNotice)에서 연결된 기술 스택 이름을 집합으로 모으기
    tech_stack_set = set()
    if hasattr(company, "job_notices"):
        for job in company.job_notices:
            if hasattr(job, "notice_tech_stacks"):
                for nts in job.notice_tech_stacks:
                    if nts.tech_stack:
                        tech_stack_set.add(nts.tech_stack.tech_stack_name)
    tech_stack_list = list(tech_stack_set)

    # has_job_notice: 현재 시각 이후 마감하는 채용 공고가 있는지 판단 (유효한 채용 공고 여부)
    has_job_notice = False
    if hasattr(company, "job_notices"):
        has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)

    # 채용 공고 리스트 (필요한 경우 간단한 정보만 반환)
    job_notices = []
    if hasattr(company, "job_notices"):
        for job in company.job_notices:
            job_notices.append({
                "job_notice_id": job.job_notice_id,
                "job_notice_title": job.job_notice_title,
                "deadline_dttm": job.deadline_dttm,
                "location": job.location,
                "min_career": job.min_career,
                "max_career": job.max_career
            })

    # 상세 정보 구성
    company_data = {
        "company_id": company.company_id,
        "company_name": company.company_name,
        "logo": company.logo,
        "likes": company.likes,
        "head_count": company.head_count,
        "all_avg_salary": company.all_avg_salary,
        "newcomer_avg_salary": company.newcomer_avg_salary,
        "total_sales_value": company.total_sales_value,
        "employee_ratio_male": company.employee_ratio_male,
        "employee_ratio_female": company.employee_ratio_female,
        "field_id": company.field_id,
        "field_name": field_name,
        "categories": categories,
        "scraped": scraped,
        "liked": liked,
        "blacklisted": blacklisted,
        "tech_stacks": tech_stack_list,
        "has_job_notice": has_job_notice,
        "job_notices": job_notices
    }

    return company_data