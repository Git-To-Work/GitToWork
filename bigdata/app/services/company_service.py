# app/services/company_service.py

from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.company import Company
from app.models.field import Field
from app.models.job_notice import JobNotice
from app.models.notice_tech_stack import NoticeTechStack
from app.models.tech_stack import TechStack

def search_companies(
    db: Session,
    user_id: Optional[int] = None,
    company_name: Optional[str] = None,
    tech_stacks: Optional[List[str]] = None,
    business_field: Optional[str] = None,
    career: Optional[int] = None,
    location: Optional[str] = None,
    keyword: Optional[str] = None,  # 추가된 파라미터
    page: int = 1,
    size: int = 20
) -> Tuple[List[Company], int]:
    """
    여러 조건에 따라 회사 목록을 검색하고 페이징 처리합니다.
    """
    query = db.query(Company)

    query = query.filter(Company.company_id > 0)

    # 회사 이름 필터
    if company_name:
        query = query.filter(Company.company_name.ilike(f"%{company_name}%"))

    # 비즈니스 분야 필터: Field와 조인 후 필터링
    if business_field:
        query = query.join(Field, Company.field_id == Field.field_id)
        query = query.filter(Field.field_name.ilike(f"%{business_field}%"))

    # 공고 관련 조건: career, location, tech_stacks, keyword 등이 있으면 JobNotice 조인
    if career is not None or location or tech_stacks or keyword:
        query = query.join(JobNotice, JobNotice.company_id == Company.company_id)

        if career is not None:
            query = query.filter(JobNotice.min_career <= career, JobNotice.max_career >= career)
        if location:
            query = query.filter(JobNotice.location.ilike(f"%{location}%"))
        if tech_stacks:
            query = query.join(NoticeTechStack, NoticeTechStack.job_notice_id == JobNotice.job_notice_id)
            query = query.join(TechStack, TechStack.tech_stack_id == NoticeTechStack.tech_stack_id)
            query = query.filter(TechStack.tech_stack_name.in_(tech_stacks))
        if keyword:
            query = query.filter(
                or_(
                    Company.company_name.ilike(f"%{keyword}%"),
                    JobNotice.job_notice_title.ilike(f"%{keyword}%")
                )
            )

    # user_id 관련 조건은 추가 처리 (예: 블랙리스트 제외 등)
    if user_id:
        # 예: user_blacklist 등을 활용하는 로직 추가 가능
        pass

    # 그룹화하여 중복 제거
    query = query.group_by(Company.company_id)

    total_count = query.count()
    offset = (page - 1) * size
    companies = query.offset(offset).limit(size).all()

    return companies, total_count
