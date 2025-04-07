from sqlalchemy import Column, Integer, String, Date, TIMESTAMP
from sqlalchemy.orm import relationship
from app.core.database import Base

class User(Base):
    __tablename__ = "user"

    user_id = Column(Integer, primary_key=True)
    github_id = Column(Integer, nullable=False)
    github_name = Column(String(100), nullable=False)
    name = Column(String(30), nullable=True)
    github_email = Column(String(255), nullable=True)
    phone = Column(String(13), nullable=True)
    birth_dt = Column(Date, nullable=True)
    experience = Column(Integer, nullable=False, default=0)
    location = Column(String(100), nullable=True)
    create_dttm = Column(TIMESTAMP, nullable=False)
    update_dttm = Column(TIMESTAMP, nullable=True)
    privacy_consent_dttm = Column(TIMESTAMP, nullable=True)
    github_access_token = Column(String(255), nullable=True)
    interest_fields = Column(String(255), nullable=True)
    delete_dttm = Column(TIMESTAMP, nullable=True)
    notification_agree_dttm = Column(TIMESTAMP, nullable=True)

    # 관계 설정
    user_alert_logs = relationship("UserAlertLog", back_populates="user", cascade="all, delete-orphan")
    user_blacklists = relationship("UserBlacklist", back_populates="user", cascade="all, delete-orphan")
    user_git_info = relationship("UserGitInfo", uselist=False, back_populates="user", cascade="all, delete-orphan")
    user_likes = relationship("UserLikes", back_populates="user", cascade="all, delete-orphan")
    user_scraps = relationship("UserScraps", back_populates="user", cascade="all, delete-orphan")
    cover_letters = relationship("CoverLetter", back_populates="user", cascade="all, delete-orphan")
