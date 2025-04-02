# app/api/routes/company.py

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.deps import get_db, get_current_user
from app.services.company_service import search_companies
from app.utils.response import success_response
from app.utils.mongo_logger import log_user_search

router = APIRouter()

"""
/**
 * 1. 메서드 설명: 사용자가 입력한 필터 조건(회사명, 기술 스택, 분야, 경력, 지역, 키워드 등)을 기반으로
 *    회사 목록을 조회하고, 응답 객체를 생성하여 반환한다.
 *
 * 2. 로직:
 *    - 현재 로그인된 사용자 정보를 기반으로 user_id를 추출한다.
 *    - 검색 필터(company_name, tech_stacks, business_field 등)를 구성하여 MongoDB에 검색 기록을 저장한다.
 *    - 검색 조건에 해당하는 회사 목록과 총 개수를 search_companies 함수를 통해 조회한다.
 *    - 조회된 각 회사에 대해 다음 정보를 구성:
 *        - 분야명(field_name) 및 카테고리 목록(categories)
 *        - 사용자가 스크랩한 여부(scraped)
 *        - 채용공고에 포함된 기술 스택 리스트(tech_stacks)
 *        - 유효한 채용공고가 존재하는지 여부(has_job_notice)
 *    - 구성된 회사 리스트와 페이징 정보를 포함한 응답 객체 반환
 *
 * 3. param:
 *    - current_user: 인증된 사용자 객체 (Depends로 주입)
 *    - db: SQLAlchemy 세션 객체
 *    - company_name: 검색할 회사 이름
 *    - tech_stacks: 필터링할 기술 스택 리스트
 *    - business_field: 비즈니스 분야명
 *    - career: 사용자의 경력 (채용공고 경력 조건에 활용)
 *    - location: 채용공고 지역
 *    - keyword: 회사명 또는 채용공고 제목에 대한 키워드 검색
 *    - page: 페이지 번호 (기본값 1)
 *    - size: 페이지당 항목 수 (기본값 20)
 *
 * 4. return: 페이징 처리된 회사 리스트 및 관련 정보가 담긴 응답 객체
 *    - companies: 필터 조건에 부합하는 회사 리스트
 *    - total: 전체 회사 수
 *    - page, size, total_page: 페이징 관련 정보
 */
"""
@router.get("/select/companies", response_model=dict)
def get_companies(
        current_user=Depends(get_current_user),
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
        user_id = current_user.user_id if hasattr(current_user, "user_id") else current_user.get("user_id")

        # 구성: 검색 필터(페이지, size 제외)
        search_filters = {
            "company_name": company_name,
            "tech_stacks": tech_stacks,
            "business_field": business_field,
            "career": career,
            "location": location,
            "keyword": keyword
        }
        search_filters = {k: v for k, v in search_filters.items() if v is not None}

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
        scraped = False
        if user_id and hasattr(company, "user_scraps"):
            scraped = any(us.user_id == user_id for us in company.user_scraps)
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
            "scraped": scraped,
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
        "total_page": total_page
    }, status_code=200, message="OK", code="SU")


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
from app.utils.recommend_companies import run_hybrid_recommendation

"""
/**
 * 1. 메서드 설명: 사용자의 GitHub 저장소 분석 정보 및 검색 히스토리를 기반으로 하이브리드 추천 알고리즘을 실행하고,
 *    검색 조건에 해당하는 회사를 조회한다.
 *
 * 2. 로직:
 *    - 현재 로그인된 사용자 정보를 통해 user_id 및 GitHub 사용자명을 추출한다.
 *    - 검색 필터(company_name, tech_stacks, business_field 등)를 구성하여 MongoDB에 검색 기록을 저장한다.
 *    - 검색 필터에 해당하는 회사 목록을 search_companies 함수를 통해 조회한다.
 *    - 현재 사용자가 좋아요, 스크랩, 블랙리스트한 회사 목록을 set으로 구성한다.
 *    - MongoDB에서 사용자 검색 히스토리 및 상세 검색 히스토리를 불러온다.
 *    - 선택된 GitHub 저장소의 커밋 및 복잡도 분석 정보를 수집한다.
 *    - SonarQube 데이터를 대체할 임시 데이터를 구성한다.
 *    - 위의 모든 사용자 관련 데이터(좋아요, 검색 기록, GitHub 분석 데이터 등)를 기반으로 run_hybrid_recommendation 함수 호출.
 *    - (현재 회사 응답 구성은 주석 처리되어 있음)
 *
 * 3. param:
 *    - selected_repositories_id: 사용자가 선택한 GitHub 저장소의 식별자
 *    - current_user: 인증된 사용자 객체 (Depends로 주입)
 *    - db: SQLAlchemy 세션 객체
 *    - company_name: 검색할 회사 이름
 *    - tech_stacks: 필터링할 기술 스택 리스트
 *    - business_field: 비즈니스 분야명
 *    - career: 사용자의 경력 (채용공고 경력 조건에 활용)
 *    - location: 채용공고 지역
 *    - keyword: 회사명 또는 채용공고 제목에 대한 키워드 검색
 *    - page: 페이지 번호 (기본값 1)
 *    - size: 페이지당 항목 수 (기본값 20)
 *
 * 4. return: 현재 주석 처리되어 있으나, 최종적으로는 추천 알고리즘 기반 회사 목록을 응답할 예정
 *    - companies: 추천된 회사 리스트
 *    - total: 전체 검색 결과 수
 *    - page, size, total_page: 페이징 정보
 *    - user_search_history: 사용자의 검색 히스토리 (추후 포함 가능)
 */
"""
@router.get("/select/companies_with_algorithm", response_model=dict)
def get_companies_with_algorithm(
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
            "business_field": business_field, #수정 필요 필터링 조건 비즈니스 필드 ->
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

    # sonarqube data 대체 임시 데이터
    data_example = {
        "language_commit_metrics": {
            "Python": {
                "commit_count": 106
            },
            "Git 설정": {
                "commit_count": 3
            },
            "JavaScript": {
                "commit_count": 7
            },
            "Java": {
                "commit_count": 37
            }
        },
        "complexity_metrics": {
            "Python": {
                "total_files": 106,
                "total_cyclomatic_complexity": 418.33014478985064,
                "total_nloc": 17686,
                "total_token_count": 198473,
                "total_parameter_count": 1175,
                "average_cyclomatic_complexity": 3.95,
                "average_nloc": 166.85,
                "average_token_count": 1872.39,
                "average_parameter_count": 11.08
            },
            "Git 설정": {
                "total_files": 3,
                "total_cyclomatic_complexity": 0.0,
                "total_nloc": 61,
                "total_token_count": 224,
                "total_parameter_count": 0,
                "average_cyclomatic_complexity": 0.0,
                "average_nloc": 20.33,
                "average_token_count": 74.67,
                "average_parameter_count": 0.0
            },
            "JavaScript": {
                "total_files": 7,
                "total_cyclomatic_complexity": 25.55,
                "total_nloc": 418,
                "total_token_count": 3044,
                "total_parameter_count": 6,
                "average_cyclomatic_complexity": 3.65,
                "average_nloc": 59.71,
                "average_token_count": 434.86,
                "average_parameter_count": 0.86
            },
            "Java": {
                "total_files": 37,
                "total_cyclomatic_complexity": 34.62488328664799,
                "total_nloc": 1440,
                "total_token_count": 10935,
                "total_parameter_count": 89,
                "average_cyclomatic_complexity": 0.94,
                "average_nloc": 38.92,
                "average_token_count": 295.54,
                "average_parameter_count": 2.41
            }
        },
        "readme_analysis": {
            "word_count": 194,
            "content_preview": (
                "![poster](./증명사진.png)\n"
                "### 정 찬 환 / 빅데이터 분석 및 AI 개발자\n"
                "***\n"
                "### 개발\n"
                "- 규칙기반 HVAC 시스템 고장진단 알고리즘 개발 [Rule_based_FDD]"
                "(https://github.com/chanhoan/chanhoan_Github/tree/main/Rule_Based_FDD)\n"
                "- 건물 시뮬레이션 데이터 활용 PV(태"
            ),
            "flesch_reading_ease": 83.18
        }
    }

    run_hybrid_recommendation(db,
                              user_github_name,
                              liked_companies_set,
                              blacklisted_companies_set,
                              scraped_companies_set,
                              user_search_history,
                              user_search_detail_history,
                              aggregate_selected_repo_stats_data,
                              data_example)

    # now = datetime.now()
    # for company in companies:
    #     field_name = company.field.field_name if company.field else None
    #     categories = []
    #     if company.field and hasattr(company.field, "categories"):
    #         categories = [
    #             {"category_id": cat.category_id, "category_name": cat.category_name}
    #             for cat in company.field.categories
    #         ]
    #     # 사용자와 연결된 상태는 미리 구성한 set을 이용하여 판단
    #     scraped = company.company_name in scraped_companies_set
    #     liked = company.company_name in liked_companies_set
    #     blacklisted = company.company_name in blacklisted_companies_set
    #
    #     tech_stack_set = set()
    #     if hasattr(company, "job_notices"):
    #         for job in company.job_notices:
    #             if hasattr(job, "notice_tech_stacks"):
    #                 for nts in job.notice_tech_stacks:
    #                     if nts.tech_stack:
    #                         tech_stack_set.add(nts.tech_stack.tech_stack_name)
    #     tech_stack_list = list(tech_stack_set)
    #     has_job_notice = False
    #     if hasattr(company, "job_notices"):
    #         has_job_notice = any(job.deadline_dttm > now for job in company.job_notices)
    #
    #     company_data = {
    #         "company_id": company.company_id,
    #         "company_name": company.company_name,
    #         "logo": company.logo,
    #         "likes": company.likes,
    #         "field_id": company.field_id,
    #         "field_name": field_name,
    #         "categories": categories,
    #         "scraped": scraped,
    #         "liked": liked,
    #         "blacklisted": blacklisted,
    #         "tech_stacks": tech_stack_list,
    #         "has_job_notice": has_job_notice
    #     }
    #     result.append(company_data)
    #
    # total_page = (total_count - 1) // size + 1
    # return success_response({
    #     "companies": result,
    #     "total": total_count,
    #     "page": page,
    #     "size": size,
    #     "total_page": total_page,
    #     "user_search_history": user_search_history
    # }, status_code=200, message="OK", code="SU")


from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime
from pymongo import MongoClient
import os

from app.core.deps import get_db, get_current_user
from app.models import Company, JobNotice, NoticeTechStack, TechStack
from app.utils.response import success_response

router = APIRouter()


@router.get("/select/new_companies_with_algo", response_model=dict)
def get_new_companies_with_algo(
        selected_repositories_id: str,
        techStacks: Optional[List[str]] = Query(None),
        field: Optional[str] = None,  # 필드 조건 (예: field_name substring)
        career: Optional[int] = None,  # 경력 조건
        keyword: Optional[str] = None,  # 회사명 또는 채용 공고 제목에 포함된 키워드
        location: Optional[List[str]] = Query(None),  # 지역 배열 조건
        page: int = 1,
        size: int = 20,
        db: Session = Depends(get_db),
        current_user=Depends(get_current_user)
):
    """
    추천 결과(추천 순서)를 기반으로 추가 필터를 적용하여 회사를 조회합니다.

    반환 데이터 형식:
    {
        "company_id": int,
        "companyName": str,
        "logo": str,
        "likes": int,
        "field_id": int,
        "field_name": str,
        "scraped": bool,
        "techStacks": [str],
        "hasJobNotice": bool
    }
    """
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
        "selected_repository_id": selected_repositories_id
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

    # (a) field 필터: Company.field 관계를 활용 (필드 이름에 substring)
    if field:
        query = query.filter(Company.field.has(Company.field.field_name.ilike(f"%{field}%")))

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
        query = query.filter(JobNotice.location.in_(location))

    # (e) techStacks 필터: JOIN NoticeTechStack와 TechStack, tech_stack_name이 techStacks에 포함
    if techStacks and len(techStacks) > 0:
        query = query.join(
            NoticeTechStack, NoticeTechStack.job_notice_id == JobNotice.job_notice_id, isouter=True
        ).join(
            TechStack, TechStack.tech_stack_id == NoticeTechStack.tech_stack_id, isouter=True
        ).filter(
            TechStack.tech_stack_name.in_(techStacks)
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

        # techStacks: 회사의 모든 채용 공고에서 NoticeTechStack을 순회하여 기술 스택 이름 수집
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
            "companyName": company.company_name,
            "logo": company.logo,
            "likes": company.likes,
            "field_id": company.field_id,
            "field_name": field_name,
            "scraped": scraped,
            "techStacks": tech_stack_list,
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
