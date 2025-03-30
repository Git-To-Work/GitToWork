from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Category(Base):
    __tablename__ = "category"

    category_id = Column(Integer, primary_key=True)
    field_id = Column(Integer, ForeignKey("field.field_id"), nullable=False)
    category_name = Column(String(100), nullable=False)

    field = relationship("Field", back_populates="categories")
