import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Intelligent Disaster Response & Relief Coordination"
    API_V1_STR: str = "/api/v1"
    APP_ENV: str = "development"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql://neondb_owner:npg_XNvzB1TlfP5O@ep-silent-dream-aiz2z687-pooler.c-4.us-east-1.aws.neon.tech:5432/neondb?sslmode=require"
    ASYNC_DATABASE_URL: str = "postgresql+asyncpg://neondb_owner:npg_XNvzB1TlfP5O@ep-silent-dream-aiz2z687-pooler.c-4.us-east-1.aws.neon.tech:5432/neondb?sslmode=require"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Cloudinary
    CLOUDINARY_CLOUD_NAME: str = "projectk-2898"
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    # Security / Auth
    JWT_SECRET_KEY: str = "super-secret-disaster-response-jwt-key-2026"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24

    # Firebase
    FIREBASE_PROJECT_ID: str = "projectk-2898"

    # AI / LLM Configuration (Groq)
    LLM_PROVIDER: str = "groq"
    GROQ_API_KEY: str = ""
    GEMINI_API_KEY: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
