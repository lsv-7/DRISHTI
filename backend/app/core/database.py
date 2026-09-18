from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

# Sync engine for migrations, seeding, and simple operations
# Replace sslmode=require for psycopg2 if needed or keep standard postgresql URL
db_url = settings.DATABASE_URL
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

engine = create_engine(
    db_url,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db_extensions():
    """Ensure PostGIS extension is created on the database."""
    with engine.connect() as conn:
        try:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
            conn.commit()
            print("✅ PostGIS extension initialized successfully.")
        except Exception as e:
            print(f"⚠️ PostGIS extension initialization note: {e}")
