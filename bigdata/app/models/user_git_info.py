from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class UserGitInfo(Base):
    __tablename__ = "user_git_info"

    user_id = Column(Integer, ForeignKey("user.user_id"), primary_key=True)
    avatar_url = Column(String(255), nullable=False)
    public_repositories = Column(Integer, nullable=False)
    followers = Column(Integer, nullable=False)
    followings = Column(Integer, nullable=False)
    create_dttm = Column(TIMESTAMP, nullable=False)
    update_dttm = Column(TIMESTAMP, nullable=True)

    # 관계
    user = relationship("User", back_populates="user_git_info")
