# app/schemas/benefit.py
from pydantic import BaseModel

class BenefitSchema(BaseModel):
    benefit_id: int
    benefit_name: str

    class Config:
        orm_mode = True
