import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env")
DATABASE_URL = os.getenv("MYSQL_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
