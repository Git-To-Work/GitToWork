from pydantic import BaseModel

class TechStackSchema(BaseModel):
    tech_stack_id: int
    tech_stack_name: str

    class Config:
        orm_mode = True
