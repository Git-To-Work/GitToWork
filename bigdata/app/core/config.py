from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # 애플리케이션 설정
    APP_NAME: str
    ENVIRONMENT: str
    DEBUG: bool

    # MySQL 설정
    MYSQL_URL: str

    # MongoDB 설정
    MONGODB_URL: str

    # Redis 설정
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_TIMEOUT: int

    # OpenAI API 설정
    OPENAI_API_KEY: str
    OPENAI_ORGANIZATION_ID: str

    # Github API 설정
    GITHUB_CLIENT_ID: str
    GITHUB_CLIENT_SECRET: str
    GITHUB_REDIRECT_URI: str

    # JWT 관련 설정
    JWT_SECRET: str
    JWT_ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_DAYS: int
    REFRESH_TOKEN_EXPIRE_DAYS: int

    # 로그 설정
    LOG_LEVEL: str
    LOG_FILE_PATH: str

    class Config:
        env_file = ".env"


settings = Settings()
