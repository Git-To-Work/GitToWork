from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class JobNoticeBase(BaseModel):
    job_notice_title: str
    deadline_dttm: datetime
    location: Optional[str] = None
    newcomer: bool
    min_career: Optional[int] = None
    max_career: Optional[int] = None
