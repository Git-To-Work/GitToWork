# app/tests/test_db_connection.py
from sqlalchemy import text
from app.core.database import engine

def test_db_connection():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))  # 아주 기본 쿼리
        print("✅ DB 연결 성공!")
    except Exception as e:
        print("❌ DB 연결 실패:", e)

if __name__ == "__main__":
    test_db_connection()