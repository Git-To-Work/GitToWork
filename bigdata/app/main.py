# app/main.py
#uvicorn app.main:app --reload --reload-dir .

import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.exceptions import UserNotFoundException, CompanyNotFoundException

logging.basicConfig(level=logging.DEBUG)
print(">>> app/main.py loaded")

import app.models  # 모든 모델을 로드

app = FastAPI()

# 커스텀 예외 핸들러
@app.exception_handler(UserNotFoundException)
async def user_not_found_exception_handler(request: Request, exc: UserNotFoundException):
    return JSONResponse(
        status_code=404,
        content={"detail": exc.message}
    )

@app.exception_handler(CompanyNotFoundException)
async def company_not_found_exception_handler(request: Request, exc: CompanyNotFoundException):
    return JSONResponse(
        status_code=404,
        content={"detail": exc.message}
    )

from app.api.routes.company import router as company_router
from app.api.routes.company_detail import router as company_detail_router

app.include_router(company_router, prefix="/api", tags=["companies"])
app.include_router(company_detail_router, prefix="/api", tags=["companies"])

# 디버깅: 등록된 경로 출력
print("Registered routes:")
for route in app.routes:
    print(route.path, route.name)
