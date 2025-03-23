from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.services.company_service import search_companies
from app.schemas.company import CompanyBase

router = APIRouter()


@router.get("/companies", response_model=dict)
def read_companies(
        db: Session = Depends(get_db),
        company_name: Optional[str] = None,
        tech_stacks: Optional[List[str]] = Query(None),
        business_field: Optional[str] = None,
        career: Optional[int] = None,
        location: Optional[str] = None,
        page: int = 1,
        size: int = 20
):
    companies, total_count = search_companies(
        db=db,
        company_name=company_name,
        tech_stacks=tech_stacks,
        business_field=business_field,
        career=career,
        location=location,
        page=page,
        size=size
    )

    # 선택: 응답에 전체 개수, 현재 페이지, 총 페이지 등도 포함 가능
    total_pages = (total_count - 1) // size + 1
    return {
        "data": [CompanyBase.from_orm(company) for company in companies],
        "total": total_count,
        "page": page,
        "size": size,
        "total_pages": total_pages
    }
