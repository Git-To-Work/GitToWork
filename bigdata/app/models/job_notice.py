from sqlalchemy import Column, Integer, String, ForeignKey, Boolean, TIMESTAMP, text
from sqlalchemy.orm import relationship
from app.core.database import Base

class JobNotice(Base):
    __tablename__ = "job_notice"

    job_notice_id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("company.company_id"))
    job_notice_title = Column(String(255), nullable=False)
    deadline_dttm = Column(TIMESTAMP, nullable=False)
    location = Column(String(255), nullable=True)
    newcomer = Column(Boolean, nullable=False, server_default=text("1"))
    min_career = Column(Integer, nullable=True)
    max_career = Column(Integer, nullable=True)

    company = relationship("Company", back_populates="job_notices")
    notice_tech_stacks = relationship("NoticeTechStack", back_populates="job_notice")
