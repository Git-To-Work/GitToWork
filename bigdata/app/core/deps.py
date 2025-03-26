# app/core/deps.py

from app.core.database import SessionLocal
from fastapi import Depends, HTTPException, status, Security
from fastapi.security import APIKeyHeader
from app.core.security import verify_access_token
from sqlalchemy.orm import Session
from app.models.user import User
from app.exceptions import UserNotFoundException

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# auto_error=False로 설정하여 토큰이 없을 때 직접 제어
api_key_header = APIKeyHeader(name="Authorization", auto_error=False)

def get_current_user(token: str = Security(api_key_header), db: Session = Depends(get_db)):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is missing",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not token.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = token[7:]  # Remove "Bearer "
    payload = verify_access_token(token)
    username = payload.get("sub")
    if not username:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload does not contain username",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = db.query(User).filter(User.github_name == username).first()
    if not user:
        raise UserNotFoundException()
    return user
