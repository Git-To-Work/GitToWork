# app/core/deps.py

from app.core.database import SessionLocal
from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from fastapi import Security
from app.core.security import verify_access_token
from sqlalchemy.orm import Session
from app.models.user import User

# 데이터베이스 세션 의존성
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# JWT 토큰 검증 후 사용자 정보 반환 의존성
api_key_header = APIKeyHeader(name="Authorization")

"""
1. 메서드 설명: API 요청 시 전달된 JWT 토큰을 검증하고, 토큰 내 'sub' 필드에서 username을 추출한 후,
   해당 username을 사용해 User 테이블에서 사용자를 검색하여 반환한다.
2. 로직:
     - 토큰을 verify_access_token() 함수를 사용해 디코딩 및 검증한다.
     - payload 에서 'sub' 키를 통해 username 을 추출한다.
     - username이 없거나 해당 사용자가 DB에 존재하지 않으면 적절한 HTTPException(401/404)을 발생시킨다.
3. param:
     - token: OAuth2PasswordBearer 로부터 추출된 Bearer 토큰
4. return:
     - User 객체 (필요에 따라 dict 형태로 변환 가능)
"""
def get_current_user(token: str = Security(api_key_header), db: Session = Depends(get_db)):
    # "Bearer " prefix 제거
    if not token.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid token format")
    token = token[7:]  # Remove "Bearer "

    payload = verify_access_token(token)
    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="Token payload does not contain username")
    user = db.query(User).filter(User.github_name == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user