# app/core/exception_handlers.py

from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from app.utils.response import error_response
from app.exceptions import (
    UserNotFoundException,
    CompanyNotFoundException,
    TokenExpiredException,
    InvalidSignatureException,
    InvalidTokenException
)

"""
FastAPI 인스턴스에 예외 핸들러들을 한꺼번에 등록하는 함수.
"""
def setup_exception_handlers(app):
    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
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
