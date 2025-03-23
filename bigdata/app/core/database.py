import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


# 환경 변수에서 MYSQL_URL을 읽어오도록 설정 (.env 파일 참조)
DATABASE_URL = os.getenv("MYSQL_URL", "mysql+mysqlconnector://ssafy:ssafy@localhost/gittowork")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
