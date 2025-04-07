from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class TechStack(Base):
    __tablename__ = "tech_stack"

    tech_stack_id = Column(Integer, primary_key=True)
    tech_stack_name = Column(String(100), nullable=False)

    notice_tech_stacks = relationship("NoticeTechStack", back_populates="tech_stack")
