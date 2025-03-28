from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Field(Base):
    __tablename__ = "field"

    field_id = Column(Integer, primary_key=True)
    field_name = Column(String(100), nullable=False)
    field_logo_url = Column(String(255), nullable=False)

    companies = relationship("Company", back_populates="field")
    categories = relationship("Category", back_populates="field")
