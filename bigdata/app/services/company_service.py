from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from app.models.company import Company
from app.models.field import Field
from app.models.job_notice import JobNotice
from app.models.notice_tech_stack import NoticeTechStack
from app.models.tech_stack import TechStack


def search_companies(
        db: Session,
        company_name: Optional[str] = None,
        tech_stacks: Optional[List[str]] = None,
        business_field: Optional[str] = None,
        career: Optional[int] = None,
        location: Optional[str] = None,
        page: int = 1,
        size: int = 20
) -> Tuple[List[Company], int]:
    """
    여러 조건에 따라 회사 목록을 검색하고 페이징 처리하여 반환합니다.

    조건:
      - 회사 이름(company_name): 회사명에 해당 키워드가 포함되는지 검색
      - 기술 스택(tech_stacks): 회사와 연결된 공고를 통해 연결된 기술 스택이 포함되는지 검색
      - 비즈니스 분야(business_field): Field 테이블과 연결된, 해당 분야를 가진 회사
      - 경력(career): 공고의 최소 경력과 최대 경력 범위 내에 포함되는지 검색
      - 지역(location): 공고의 지역 정보에 해당 문자열이 포함되는지 검색
    """
    # 기본 쿼리: Company 모델 기준
    query = db.query(Company)

    # 1. 회사 이름 필터 (대소문자 구분 없이 LIKE 검색)
    if company_name:
        query = query.filter(Company.company_name.ilike(f"%{company_name}%"))

    # 2. 비즈니스 분야 필터: Field와 조인 후, 해당 분야 검색
    if business_field:
        query = query.join(Field, Company.field_id == Field.field_id)
        query = query.filter(Field.field_name.ilike(f"%{business_field}%"))

    # 3. 공고 관련 필터 (경력, 지역, 기술 스택)
    #    공고 조건이 하나라도 있으면 JobNotice와 조인
    if career is not None or location or tech_stacks:
        query = query.join(JobNotice, JobNotice.company_id == Company.company_id)

        # 경력: 공고의 min_career <= career <= max_career
        if career is not None:
            query = query.filter(JobNotice.min_career <= career, JobNotice.max_career >= career)

        # 지역: 공고의 지역 필드에 location 문자열 포함
        if location:
            query = query.filter(JobNotice.location.ilike(f"%{location}%"))

        # 기술 스택: 공고와 연결된 NoticeTechStack, TechStack 조인 후 조건 적용
        if tech_stacks:
            query = query.join(NoticeTechStack, NoticeTechStack.job_notice_id == JobNotice.job_notice_id)
            query = query.join(TechStack, TechStack.tech_stack_id == NoticeTechStack.tech_stack_id)
            query = query.filter(TechStack.tech_stack_name.in_(tech_stacks))

    # 중복 회사가 여러 공고 때문에 발생할 수 있으므로 그룹화
    query = query.group_by(Company.company_id)

    # 페이징 처리: 전체 개수를 구하고, offset과 limit 적용
    total_count = query.count()
    offset = (page - 1) * size
    companies = query.offset(offset).limit(size).all()

    return companies, total_count
