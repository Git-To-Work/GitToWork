# app/core/mongo.py
import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")

# MongoClient 생성
client = MongoClient(MONGODB_URL)

db = client.get_default_database()

def get_mongo_db():
    return db
