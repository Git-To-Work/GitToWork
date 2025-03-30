from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class UserBlacklist(Base):
    __tablename__ = "user_blacklist"

    user_id = Column(Integer, ForeignKey("user.user_id"), primary_key=True)
    company_id = Column(Integer, ForeignKey("company.company_id"), primary_key=True)

    # 관계 설정
    user = relationship("User", back_populates="user_blacklists")
    # Company 모델과의 관계는 단방향으로 설정하거나 필요에 따라 back_populates 추가 가능
    company = relationship("Company")
