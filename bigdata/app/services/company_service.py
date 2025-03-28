# app/services/company_service.py

from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.company import Company
from app.models.field import Field
from app.models.job_notice import JobNotice
from app.models.notice_tech_stack import NoticeTechStack
from app.models.tech_stack import TechStack

"""
/**
 * 1. 메서드 설명: 다양한 필터 조건(회사명, 기술 스택, 분야, 경력, 지역, 키워드 등)을 기반으로
 *    회사 목록을 검색하고 페이징 처리된 결과를 반환한다.
 *
 * 2. 로직:
 *    - 회사 ID가 0보다 큰 경우만 대상으로 기본 필터링한다.
 *    - 회사명, 비즈니스 분야, 기술 스택, 경력, 지역, 키워드 등의 조건이 존재하면 해당 조건을 쿼리에 추가한다.
 *    - career, location, tech_stacks, keyword 중 하나라도 있을 경우 JobNotice 및 관련 테이블과 조인한다.
 *    - 필요 시 Field, JobNotice, NoticeTechStack, TechStack 테이블을 조인하여 필터링을 적용한다.
 *    - 키워드 검색은 회사명 또는 채용 공고 제목에서 수행한다.
 *    - 중복 제거를 위해 company_id 기준으로 그룹화한다.
 *    - 페이징 처리를 위해 전체 개수를 구하고, 오프셋(offset)과 제한(limit)을 적용한다.
 *
 * 3. param:
 *    - db: SQLAlchemy 세션 객체
 *    - user_id: 사용자 ID (예: 블랙리스트 필터링 등 사용자 기반 조건에 활용 가능)
 *    - company_name: 검색할 회사 이름
 *    - tech_stacks: 필터링할 기술 스택 리스트
 *    - business_field: 비즈니스 분야명
 *    - career: 사용자의 경력 (해당 경력 범위에 맞는 채용 공고 필터링)
 *    - location: 채용 공고 지역
 *    - keyword: 회사명 또는 채용 공고 제목에 대해 키워드 검색
 *    - page: 페이지 번호 (기본값 1)
 *    - size: 페이지당 항목 수 (기본값 20)
 *
 * 4. return: (회사 리스트, 전체 결과 개수)를 튜플로 반환
 *    - companies: 조건에 맞는 회사 객체 리스트
 *    - total_count: 조건에 부합하는 전체 회사 개수
 */
"""
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
    query = db.query(Company)

    query = query.filter(Company.company_id > 0)

    if company_name:
        query = query.filter(Company.company_name.ilike(f"%{company_name}%"))

    if business_field:
        query = query.join(Field, Company.field_id == Field.field_id)
        query = query.filter(Field.field_name.ilike(f"%{business_field}%"))

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

    query = query.group_by(Company.company_id)

    total_count = query.count()
    offset = (page - 1) * size
    companies = query.offset(offset).limit(size).all()

    return companies, total_count
