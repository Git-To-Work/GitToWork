# app/schemas/company_detail.py
from pydantic import BaseModel
from typing import Optional, List
from app.schemas.benefit import BenefitSchema

class CompanyDetail(BaseModel):
    company_id: int
    company_name: str
    logo: Optional[str] = None
    head_count: Optional[int] = None
    all_avg_salary: Optional[int] = None
    newcomer_avg_salary: Optional[int] = None
    likes: int = 0
    total_sales_value: Optional[int] = None
    employee_ratio_male: Optional[int] = None
    employee_ratio_female: Optional[int] = None
    field_id: int

    benefits: Optional[List[BenefitSchema]] = []

    class Config:
        orm_mode = True
