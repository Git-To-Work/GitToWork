# app/models/task.py
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Task(Base):
    __tablename__ = "task"

    task_id = Column(Integer, primary_key=True, index=True)
    task_name = Column(String(100), nullable=False, unique=True)

    # JobNotice와의 양방향 관계
    job_notices = relationship("JobNotice", back_populates="task")
