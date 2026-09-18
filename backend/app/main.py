from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.core.database import engine, Base, SessionLocal, init_db_extensions
from app.api.v1 import api_v1_router
from app.api.v1.websocket import router as ws_router
from app.services.seed_data import seed_database


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup sequence
    print("🚀 Initializing Disaster Response Backend...")
    try:
        init_db_extensions()
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created/verified.")
        
        db = SessionLocal()
        seed_database(db)
        db.close()
    except Exception as e:
        print(f"⚠️ Database startup initialization warning: {e}")
    yield
    # Shutdown sequence
    print("🛑 Shutting down Disaster Response Backend.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(api_v1_router)
app.include_router(ws_router)


@app.get("/")
def root_endpoint():
    return {
        "status": "online",
        "app_name": settings.PROJECT_NAME,
        "docs_url": "/docs",
        "api_v1": settings.API_V1_STR
    }


@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "FastAPI Backend"}


@app.get(f"{settings.API_V1_STR}/health")
def api_v1_health():
    return {"status": "healthy", "version": "1.0.0"}