# app/models/notice_task.py
from sqlalchemy import Table, Column, Integer, ForeignKey
from app.core.database import Base

notice_task = Table(
    "notice_task",
    Base.metadata,
    Column("job_notice_id", Integer, ForeignKey("job_notice.job_notice_id"), primary_key=True),
    Column("task_id", Integer, ForeignKey("task.task_id"), primary_key=True)
)
