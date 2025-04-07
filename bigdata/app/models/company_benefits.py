from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class CompanyBenefits(Base):
    __tablename__ = "company_benefits"

    company_id = Column(Integer, ForeignKey("company.company_id"), primary_key=True)
    benefit_id = Column(Integer, ForeignKey("benefit.benefit_id"), primary_key=True)

    company = relationship("Company", back_populates="company_benefits")
    benefit = relationship("Benefit")
