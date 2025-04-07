from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class NoticeTechStack(Base):
    __tablename__ = "notice_tech_stack"

    job_notice_id = Column(Integer, ForeignKey("job_notice.job_notice_id"), primary_key=True)
    tech_stack_id = Column(Integer, ForeignKey("tech_stack.tech_stack_id"), primary_key=True)

    job_notice = relationship("JobNotice", back_populates="notice_tech_stacks")
    tech_stack = relationship("TechStack", back_populates="notice_tech_stacks")
