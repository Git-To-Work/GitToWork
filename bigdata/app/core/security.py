# app/core/security.py

import os
from jose import jwt, JWTError
from jose.exceptions import ExpiredSignatureError
from dotenv import load_dotenv
from app.exceptions import TokenExpiredException, InvalidSignatureException, InvalidTokenException

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")

def verify_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except ExpiredSignatureError as e:
        # 토큰 만료 시
        raise TokenExpiredException(f"Token has expired: {str(e)}")
    except JWTError as e:
        # 서명 오류 또는 기타 토큰 에러 처리
        if "signature" in str(e).lower():
            raise InvalidSignatureException(f"Invalid token signature: {str(e)}")
        else:
            raise InvalidTokenException(f"Invalid token: {str(e)}")
