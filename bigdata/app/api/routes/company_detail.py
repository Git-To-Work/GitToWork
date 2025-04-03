# app/api/routes/company_detail.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.deps import get_db, get_current_user
from app.models.company import Company
from app.exceptions import CompanyNotFoundException
from app.utils.response import success_response
from app.utils.mongo_logger import log_user_search_detail

router = APIRouter()

@router.get("/select/company/{company_id}", response_model=dict)
def read_company_detail(
    company_id: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 인증된 사용자 ID 추출
    user_id = current_user.user_id

    # MongoDB에 사용자 상세 조회 로그 저장
    log_user_search_detail(user_id, company_id)

    # 회사 조회
    company = db.query(Company).filter(Company.company_id == company_id).first()
    if not company:
        raise CompanyNotFoundException()

    now = datetime.now()
    field_name = company.field.field_name if company.field else None

    categories = []
    if company.field and hasattr(company.field, "categories"):
        categories = [
            {"category_id": cat.category_id, "category_name": cat.category_name}
            for cat in company.field.categories
        ]

    scraped = False
    if hasattr(company, "user_scraps"):
        scraped = any(us.user_id == user_id for us in company.user_scraps)

    liked = False
    if hasattr(company, "user_likes"):
        liked = any(ul.user_id == user_id for ul in company.user_likes)

    blacklisted = False
    if hasattr(company, "user_blacklists"):
        blacklisted = any(ub.user_id == user_id for ub in company.user_blacklists)

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

    job_notices = []
    if hasattr(company, "job_notices"):
        for job in company.job_notices:
            job_tech_stack_set = set()
            if hasattr(job, "notice_tech_stacks"):
                for nts in job.notice_tech_stacks:
                    if nts.tech_stack:
                        job_tech_stack_set.add(nts.tech_stack.tech_stack_name)
            job_tech_stack_list = list(job_tech_stack_set)
            job_notices.append({
                "job_notice_id": job.job_notice_id,
                "job_notice_title": job.job_notice_title,
                "deadline_dttm": job.deadline_dttm,
                "location": job.location,
                "min_career": job.min_career,
                "max_career": job.max_career,
                "tech_stacks": job_tech_stack_list
            })

    # benefit 정보 처리: m:n 관계 company_benefits를 benefit_category별로 그룹핑
    benefits_dict = {}
    if hasattr(company, "company_benefits"):
        for cb in company.company_benefits:
            if hasattr(cb, "benefit") and cb.benefit:
                benefit = cb.benefit
                # benefit_category가 있는 경우, 카테고리 이름 사용, 없으면 "기타"로 처리
                if hasattr(benefit, "benefit_category") and benefit.benefit_category:
                    category_name = benefit.benefit_category.benefit_category_name
                else:
                    category_name = "기타"
                if category_name not in benefits_dict:
                    benefits_dict[category_name] = []
                benefits_dict[category_name].append(benefit.benefit_name)

    # benefit 정보를 sections 형식으로 구성
    benefits_sections = []
    for category_name, benefit_names in benefits_dict.items():
        benefits_sections.append({
            "head": category_name,
            "body": benefit_names
        })
    benefits_data = {
        "title": "복리후생",
        "sections": benefits_sections
    }

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
        "scraped": scraped,
        "liked": liked,
        "blacklisted": blacklisted,
        "tech_stacks": tech_stack_list,
        "has_job_notice": has_job_notice,
        "job_notices": job_notices,
        "benefits": benefits_data  # 추가된 benefit 정보
    }

    return success_response({
        "result": company_data
    }, status_code=200, message="Success.", code="SU")
