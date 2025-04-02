from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Benefit(Base):
    __tablename__ = "benefit"

    benefit_id = Column(Integer, primary_key=True, autoincrement=True)
    benefit_name = Column(String(255), nullable=False)
    # benefit_category_id가 NULL일 수 있으므로 nullable=True
    benefit_category_id = Column(Integer, ForeignKey("benefit_category.benefit_category_id"), nullable=True)

    # BenefitCategory와의 관계: benefit_category가 없으면 None이 될 수 있음
    benefit_category = relationship("BenefitCategory", back_populates="benefits")
