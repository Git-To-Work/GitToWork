# app/core/deps.py
from app.core.database import SessionLocal
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.security import verify_access_token

# 데이터베이스 세션 의존성
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# JWT 토큰 검증 후 사용자 정보 반환 의존성
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

"""
1. 메서드 설명: API 요청 시 전달된 JWT 토큰을 검증하고, 토큰 내 'sub' 필드에서 username을 추출하여 반환한다.
2. 로직:
     - 토큰을 verify_access_token() 함수를 사용해 디코딩 및 검증한다.
     - payload 에서 'sub' 키를 통해 username 을 추출한다.
     - username 이 없으면 401 Unauthorized 에러를 발생시킨다.
3. param:
     - token: OAuth2PasswordBearer 로부터 추출된 Bearer 토큰
4. return:
     - {"username": username} 형태의 사용자 정보 (필요에 따라 DB 조회 추가 가능)
"""
def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = verify_access_token(token)
    username = payload.get("sub")
    if not username:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload does not contain username"
        )
    return {"username": username}
