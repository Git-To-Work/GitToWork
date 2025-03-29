# app/models/company.py

from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Company(Base):
    __tablename__ = "company"

    company_id = Column(Integer, primary_key=True)
    company_name = Column(String(100), nullable=False)
    logo = Column(String(255), nullable=True)
    head_count = Column(Integer, nullable=True)
    all_avg_salary = Column(Integer, nullable=True)
    newcomer_avg_salary = Column(Integer, nullable=True)
    likes = Column(Integer, nullable=False, default=0)
    total_sales_value = Column(Integer, nullable=True)
    employee_ratio_male = Column(Integer, nullable=True)
    employee_ratio_female = Column(Integer, nullable=True)
    field_id = Column(Integer, ForeignKey("field.field_id"), nullable=False)

    # 관계 설정:
    field = relationship("Field", back_populates="companies")
    job_notices = relationship("JobNotice", back_populates="company")
    company_benefits = relationship("CompanyBenefits", back_populates="company")
    user_scraps = relationship("UserScraps", back_populates="company")
    user_likes = relationship("UserLikes", back_populates="company")
    user_blacklists = relationship("UserBlacklist", back_populates="company")