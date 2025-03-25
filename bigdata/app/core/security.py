# app/core/security.py
import os
from jose import jwt, JWTError
from fastapi import HTTPException, status
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")

"""
1. 메서드 설명: 주어진 access token을 검증하고, 토큰의 페이로드(예: 사용자 정보)를 반환한다.
2. 로직:
     - JWT_SECRET과 JWT_ALGORITHM을 사용해 토큰 디코딩을 시도.
     - 토큰이 유효하지 않거나 만료된 경우, JWTError를 발생시키고 HTTPException(401 Unauthorized)를 던진다.
3. param:
     - token: 검증할 JWT access token
4. return:
     - 토큰의 페이로드 (dict), 예: {"sub": "username", "exp": 1680000000, ...}
"""
def verify_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        print("core/security/verify_access_token : ")
        print(payload)
        print(" ")
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
