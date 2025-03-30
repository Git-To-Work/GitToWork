# app/utils/response.py

from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder

def success_response(result: dict, status_code: int = 200, message: str = "OK", code: str = "SU") -> JSONResponse:
    content = jsonable_encoder({
        "status": status_code,
        "message": message,
        "code": code,
        "result": result
    })
    return JSONResponse(status_code=status_code, content=content)

def error_response(status_code: int, message: str, code: str) -> JSONResponse:
    content = jsonable_encoder({
        "status": status_code,
        "message": message,
        "code": code
    })
    return JSONResponse(status_code=status_code, content=content)
