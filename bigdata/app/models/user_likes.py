from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class UserLikes(Base):
    __tablename__ = "user_likes"

    user_id = Column(Integer, ForeignKey("user.user_id"), primary_key=True)
    company_id = Column(Integer, ForeignKey("company.company_id"), primary_key=True)

    # 관계 설정
    user = relationship("User", back_populates="user_likes")
    company = relationship("Company")
