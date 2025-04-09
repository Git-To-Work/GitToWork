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

def extract_flags(company: Company, user_id: str) -> (bool, bool, bool):
    """회사에 대한 스크랩, 좋아요, 블랙리스트 여부를 추출."""
    scraped = any(us.user_id == user_id for us in getattr(company, "user_scraps", []))
    liked = any(ul.user_id == user_id for ul in getattr(company, "user_likes", []))
    blacklisted = any(ub.user_id == user_id for ub in getattr(company, "user_blacklists", []))
    return scraped, liked, blacklisted

def extract_tech_stacks(company: Company) -> list:
    """회사에 소속된 모든 채용 공고에서 기술 스택 이름을 수집."""
    tech_stack_set = set()
    for job in getattr(company, "job_notices", []):
        for nts in getattr(job, "notice_tech_stacks", []):
            if nts.tech_stack and nts.tech_stack.tech_stack_name:
                tech_stack_set.add(nts.tech_stack.tech_stack_name)
    return list(tech_stack_set)

def extract_job_notices(company: Company) -> list:
    """회사에 연결된 채용 공고 정보를 가공하여 리스트로 반환."""
    job_notices = []
    for job in getattr(company, "job_notices", []):
        job_tech_stack_set = set()
        for nts in getattr(job, "notice_tech_stacks", []):
            if nts.tech_stack and nts.tech_stack.tech_stack_name:
                job_tech_stack_set.add(nts.tech_stack.tech_stack_name)
        job_notices.append({
            "job_notice_id": job.job_notice_id,
            "job_notice_title": job.job_notice_title,
            "deadline_dttm": job.deadline_dttm,
            "location": job.location,
            "min_career": job.min_career,
            "max_career": job.max_career,
            "tech_stacks": list(job_tech_stack_set)
        })
    return job_notices


def extract_benefits(company: Company) -> dict:
    """회사 복리후생 정보를 benefit_category별로 그룹핑하여 구성.

    company_benefits 테이블의 데이터를 기반으로,
    각 benefit 항목의 benefit_category.benefit_category_name을 키로 사용하여 그룹화합니다.
    """
    benefits_dict = {}
    # company.company_benefits는 이미 회사와 연결된 복리후생 항목(benefit)들을 포함하고 있다고 가정합니다.
    for cb in getattr(company, "company_benefits", []):
        # 각 연관 정보에서 benefit이 존재하는지 체크
        if hasattr(cb, "benefit") and cb.benefit:
            benefit = cb.benefit
            # benefit_category가 연결되어 있다면 해당 카테고리명, 아니면 "기타"로 지정
            if hasattr(benefit, "benefit_category") and benefit.benefit_category:
                category_name = benefit.benefit_category.benefit_category_name
            else:
                category_name = "기타"
            # 해당 카테고리 이름을 키로 하여 benefit_name을 리스트에 추가
            benefits_dict.setdefault(category_name, []).append(benefit.benefit_name)

    # 딕셔너리를 JSON의 sections 형식("head", "body")으로 변환
    benefits_sections = [{"head": cat, "body": names} for cat, names in benefits_dict.items()]
    return {"title": "복리후생", "sections": benefits_sections}


def format_company_data(company: Company, user_id: str) -> dict:
    """회사 상세 정보를 최종 응답 데이터 형식으로 구성."""
    now = datetime.now()
    field_name = company.field.field_name if company.field else None
    scraped, liked, blacklisted = extract_flags(company, user_id)
    tech_stack_list = extract_tech_stacks(company)
    has_job_notice = any(job.deadline_dttm > now for job in getattr(company, "job_notices", []))
    job_notices = extract_job_notices(company)
    benefits_data = extract_benefits(company)

    return {
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
        "benefits": benefits_data
    }

@router.get("/select/company/{company_id}", response_model=dict)
def read_company_detail(
    company_id: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if company_id < 1:
        raise HTTPException(status_code=400, detail="company_id는 1 이상이어야 합니다.")

    user_id = current_user.user_id
    log_user_search_detail(user_id, company_id)

    company = db.query(Company).filter(Company.company_id == company_id).first()
    if not company:
        raise CompanyNotFoundException()

    company_data = format_company_data(company, user_id)
    return success_response(
        {"result": company_data},
        status_code=200,
        message="Success.",
        code="SU"
    )
