from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Benefit(Base):
    __tablename__ = "benefit"

    benefit_id = Column(Integer, primary_key=True)
    benefit_name = Column(String(255), nullable=False)

    company_benefits = relationship("CompanyBenefits", back_populates="benefit")
