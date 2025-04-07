# app/schemas/company.py
from pydantic import BaseModel, validator
from typing import Optional

class CompanyBase(BaseModel):
    company_id: int
    company_name: str
    logo: Optional[str] = None
    head_count: Optional[int] = None
    all_avg_salary: Optional[int] = None
    newcomer_avg_salary: Optional[int] = None
    likes: Optional[int] = 0
    total_sales_value: Optional[int] = None
    employee_ratio_male: Optional[int] = None
    employee_ratio_female: Optional[int] = None
    field_id: int

    class Config:
        from_attributes = True

    @validator("likes", pre=True, always=True)
    def set_likes(cls, v):
        return 0 if v is None else v
