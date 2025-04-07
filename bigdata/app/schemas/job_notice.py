from pydantic import BaseModel
from typing import Optional, List
from app.schemas.job_notice_base import JobNoticeBase
from app.schemas.tech_stack import TechStackSchema

class JobNoticeSchema(JobNoticeBase):
    job_notice_id: int
    company_id: int
    notice_tech_stacks: Optional[List[TechStackSchema]] = []

    class Config:
        orm_mode = True
