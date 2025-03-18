# syntax=docker/dockerfile:1
FROM python:3.11

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# 빌드 컨텍스트가 bigdata 폴더이므로, 같은 위치에 있는 requirements.txt를 복사
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 빌드 컨텍스트 내의 app 폴더(실제 소스 코드)를 컨테이너의 /app 디렉터리로 복사
COPY app/ .

EXPOSE 8000

# main.py에 FastAPI 애플리케이션이 "app" 변수로 정의되어 있다고 가정
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

