from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Benefit(Base):
    __tablename__ = "benefit"

    benefit_id = Column(Integer, primary_key=True, autoincrement=True)
    benefit_name = Column(String(255), nullable=False)
    benefit_category_id = Column(Integer, ForeignKey("benefit_category.benefit_category_id"), nullable=True)

    benefit_category = relationship("BenefitCategory", back_populates="benefits")
