from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class UserAlertLog(Base):
    __tablename__ = "user_alert_log"

    alert_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("user.user_id"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    message = Column(String(255), nullable=False)
    create_dttm = Column(TIMESTAMP, nullable=False)

    # 관계
    user = relationship("User", back_populates="user_alert_logs")
