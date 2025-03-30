from sqlalchemy import Column, String, Integer, TIMESTAMP, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class CoverLetterAnalysis(Base):
    __tablename__ = "cover_letter_analysis"

    cover_letter_analysis_id = Column(String(255), primary_key=True)
    file_id = Column(Integer, ForeignKey("cover_letter.file_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("user.user_id"), nullable=False)
    analysis_result = Column(Text, nullable=True)
    global_capability = Column(Integer, nullable=True)
    challenge_spirit = Column(Integer, nullable=True)
    sincerity = Column(Integer, nullable=True)
    communication_skill = Column(Integer, nullable=True)
    achievement_orientation = Column(Integer, nullable=True)
    responsibility = Column(Integer, nullable=True)
    honesty = Column(Integer, nullable=True)
    creativity = Column(Integer, nullable=True)
    create_dttm = Column(TIMESTAMP, nullable=True)

    # 관계
    cover_letter = relationship("CoverLetter", back_populates="analyses")
