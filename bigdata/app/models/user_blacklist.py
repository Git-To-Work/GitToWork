from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class UserBlacklist(Base):
    __tablename__ = "user_blacklist"

    user_id = Column(Integer, ForeignKey("user.user_id"), primary_key=True)
    company_id = Column(Integer, ForeignKey("company.company_id"), primary_key=True)

    # 관계 설정
    user = relationship("User", back_populates="user_blacklists")
    company = relationship("Company")
