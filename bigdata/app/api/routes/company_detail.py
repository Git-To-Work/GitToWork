# app/api/routes/company_detail.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.deps import get_db, get_current_user
from app.models.company import Company

router = APIRouter()


@router.get("/select/company/{company_id}", response_model=dict)
def read_company_detail(
        company_id: int,
        current_user=Depends(get_current_user),  # 인증된 사용자 정보
        db: Session = Depends(get_db)
):
    # current_user에서 user_id 추출 (User 객체 또는 dict)
    user_id = current_user.user_id if hasattr(current_user, "user_id") else current_user.get("user_id")

    company = db.query(Company).filter(Company.company_id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    now = datetime.now()

    # Field 정보
    field_name = company.field.field_name if company.field else None

    # Category 정보
    categories = []
    if company.field and hasattr(company.field, "categories"):
        categories = [
            {"category_id": cat.category_id, "category_name": cat.category_name}
            for cat in company.field.categories
        ]

    # scraped: user_scraps 관계 확인
    scraped = False
    if user_id and hasattr(company, "user_scraps"):
        scraped = any(us.user_id == user_id for us in company.user_scraps)

    # liked: user_likes 관계 확인
    liked = False
    if user_id and hasattr(company, "user_likes"):
        liked = any(ul.user_id == user_id for ul in company.user_likes)

    # blacklisted: user_blacklists 관계 확인
    blacklisted = False
    if user_id and hasattr(company, "user_blacklists"):
        blacklisted = any(ub.user_id == user_id for ub in company.user_blacklists)

    # tech_stacks: 모든 공고에서 TechStack 이름 수집
    tech_stack_set = set()
    if hasattr(company, "job_notices"):
        for job in company.job_notices:
            if hasattr(job, "notice_tech_stacks"):
                for nts in job.notice_tech_stacks:
                    if nts.tech_stack:
                        tech_stack_set.add(nts.tech_stack.tech_stack_name)
    tech_stack_list = list(tech_stack_set)

    # has_job_notice: 현재 시각 이후 마감하는 채용 공고 여부
    has_job_notice = False
    if hasattr(company, "job_notices"):
        has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)

    # 채용 공고 리스트 (간단 정보)
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
