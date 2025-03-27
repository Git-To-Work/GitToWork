# app/utils/mongo_logger.py
from datetime import datetime
from fastapi import HTTPException
from app.core.mongo import get_mongo_db

# 검색 로그 저장 컬렉션 이름
SEARCH_HISTORY_COLLECTION = "user_search_history"
SEARCH_DETAIL_COLLECTION = "user_search_detail_history"

def log_user_search(user_id: int, filters: dict) -> None:
    db = get_mongo_db()
    collection = db[SEARCH_HISTORY_COLLECTION]

    log_doc = {
        "user_id": user_id,
        "timestamp": datetime.utcnow(),
        "filters": filters
    }

    try:
        collection.insert_one(log_doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log search history: {str(e)}")

def log_user_search_detail(user_id: int, searched_company_id: int):
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

"""
해당 user_id의 검색 로그 기록을 MongoDB의 collection_name을 가진 컬렉션에서 조회하여 리스트로 반환합니다.
각 로그는 {"user_id": ..., "timestamp": ..., "filters": ...} 구조를 가집니다.
"""
def get_user_search_history(user_id: int, collection_name: str) -> list:

    db = get_mongo_db()
    collection = db[collection_name]
    try:
        logs = list(collection.find({"user_id": user_id}))
        for log in logs:
            if "timestamp" in log and isinstance(log["timestamp"], datetime):
                log["timestamp"] = log["timestamp"].isoformat()
            if "_id" in log:
                log["_id"] = str(log["_id"])
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve search history: {str(e)}")
