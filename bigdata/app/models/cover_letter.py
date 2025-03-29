from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class CoverLetter(Base):
    __tablename__ = "cover_letter"

    file_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("user.user_id"), nullable=False)
    origin_name = Column(String(255), nullable=False)
    file_url = Column(String(255), nullable=False)
    create_dttm = Column(TIMESTAMP, nullable=False)
    title = Column(String(255), nullable=False)

    # 관계
    user = relationship("User", back_populates="cover_letters")
    analyses = relationship("CoverLetterAnalysis", back_populates="cover_letter", cascade="all, delete-orphan")
