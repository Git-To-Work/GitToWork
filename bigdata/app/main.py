# app/main.py

import logging
from fastapi import FastAPI, Request, HTTPException
from app.exceptions import UserNotFoundException, CompanyNotFoundException, TokenExpiredException, InvalidSignatureException, InvalidTokenException
from app.utils.response import error_response

logging.basicConfig(level=logging.DEBUG)
print(">>> app/main.py loaded")

app = FastAPI()

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    # 예를 들어, HTTPException 발생 시 code를 "HTTPE"로 지정 (원하는 코드로 변경 가능)
    return error_response(status_code=exc.status_code, message=exc.detail, code="MT")

@app.exception_handler(UserNotFoundException)
async def user_not_found_exception_handler(request: Request, exc: UserNotFoundException):
    return error_response(status_code=404, message=exc.message, code="NF")

@app.exception_handler(CompanyNotFoundException)
async def company_not_found_exception_handler(request: Request, exc: CompanyNotFoundException):
    return error_response(status_code=404, message=exc.message, code="NF")

@app.exception_handler(TokenExpiredException)
async def token_expired_exception_handler(request: Request, exc: TokenExpiredException):
    return error_response(status_code=401, message=exc.message, code=exc.code)

@app.exception_handler(InvalidSignatureException)
async def invalid_signature_exception_handler(request: Request, exc: InvalidSignatureException):
    return error_response(status_code=401, message=exc.message, code=exc.code)

@app.exception_handler(InvalidTokenException)
async def invalid_token_exception_handler(request: Request, exc: InvalidTokenException):
    return error_response(status_code=401, message=exc.message, code=exc.code)

from app.api.routes.company import router as company_router
from app.api.routes.company_detail import router as company_detail_router

app.include_router(company_router, prefix="/api", tags=["companies"])
app.include_router(company_detail_router, prefix="/api", tags=["companies"])

print("Registered routes:")
for route in app.routes:
    print(route.path, route.name)
