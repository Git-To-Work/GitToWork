# uvicorn app.main:app --reload
# uvicorn app.main:app --reload --reload-dir .

print(">>> app/main.py loaded")

# 반드시 먼저 모든 모델을 로드해서 __init__.py에 의해 등록되도록 함
import app.models

from fastapi import FastAPI
from app.api.routes.company import router as company_router

app = FastAPI()

app.include_router(company_router, prefix="/api", tags=["companies"])

# 디버깅: 등록된 경로 목록 출력
print("Registered routes:")
for route in app.routes:
    print(route.path, route.name)
