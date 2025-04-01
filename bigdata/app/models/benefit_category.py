from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class BenefitCategory(Base):
    __tablename__ = "benefit_category"

    benefit_category_id = Column(Integer, primary_key=True, autoincrement=True)
    benefit_category_name = Column(String(100), nullable=False)

    benefits = relationship("Benefit", back_populates="benefit_category")
