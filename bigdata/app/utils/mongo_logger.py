# app/utils/mongo_logger.py
from datetime import datetime
from fastapi import HTTPException
from app.core.mongo import get_mongo_db

#검색 로그 저장
SEARCH_HISTORY_COLLECTION = "user_search_logs"

"""
사용자의 검색 필터 정보를 MongoDB의 user_search_logs 컬렉션에 저장합니다.
페이지와 사이즈 정보는 제외하고, user_id, 검색 조건, 검색 요청 시각 등을 기록합니다.
"""
def log_user_search(user_id: int, filters: dict) -> None:
    db = get_mongo_db()
    collection = db[SEARCH_HISTORY_COLLECTION]

    # 저장할 문서 구성
    log_doc = {
        "user_id": user_id,
        "timestamp": datetime.utcnow(),
        "filters": filters
    }

    try:
        collection.insert_one(log_doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log search history: {str(e)}")

#상세 조회 로그 저장
SEARCH_DETAIL_COLLECTION = "user_search_detail_log"

def log_user_search_detail(user_id: int, searched_company_id: int):
    """
    회사 상세 조회 시, user_id와 회사 ID를 MongoDB에 저장합니다.
    구조 예:
    {
        "user_id": 12345,
        "timestamp": "2025-03-25T14:35:00Z",
        "searched_company_id": 12
    }
    """
    db = get_mongo_db()
    collection = db[SEARCH_DETAIL_COLLECTION]

    doc = {
        "user_id": user_id,
        "timestamp": datetime.utcnow(),
        "searched_company_id": searched_company_id
    }

    try:
        collection.insert_one(doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log search detail: {str(e)}")