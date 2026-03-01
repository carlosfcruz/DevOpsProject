from contextlib import asynccontextmanager
import asyncio
from fastapi import HTTPException
from fastapi import FastAPI, Depends
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy.orm import Session
from datetime import datetime, timezone
import os
import psycopg2
import redis
import logging
from pythonjsonlogger import jsonlogger

from app.database import engine, SessionLocal
from app.models import Base, User


# -----------------------------
# Logging
# -----------------------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

for handler in logger.handlers:
    logger.removeHandler(handler)

logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter('%(asctime)s %(levelname)s %(name)s %(message)s')
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)


# -----------------------------
# Lifespan (startup / shutdown)
# -----------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("APP_ENV") == "development":
        Base.metadata.create_all(bind=engine)
    yield

# Create FastAPI instance
app = FastAPI(lifespan=lifespan)
Instrumentator().instrument(app).expose(app)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# -----------------------------
# Basic root endpoint
# -----------------------------
@app.get("/")
def root():
    return {
        "app_name": os.getenv("APP_NAME", "platform"),
        "environment": os.getenv("APP_ENV"),
        "status": "running"
    }


# -----------------------------
# Health check helpers
# -----------------------------
def check_database():
    try:
        connection = psycopg2.connect(
            host=os.getenv("POSTGRES_HOST"),
            database=os.getenv("POSTGRES_DB"),
            user=os.getenv("POSTGRES_USER"),
            password=os.getenv("POSTGRES_PASSWORD"),
        )
        connection.close()
        return "ok"
    except Exception:
        return "error"


def check_redis():
    try:
        r = redis.Redis(host=os.getenv("REDIS_HOST"), port=6379)
        r.ping()
        return "ok"
    except Exception:
        return "error"


# -----------------------------
# Global health endpoint
# -----------------------------
@app.get("/health")
def health():
    db_status = check_database()
    redis_status = check_redis()

    overall_status = "ok" if db_status == "ok" and redis_status == "ok" else "degraded"
    logger.info("Health check endpoint called", extra={
        "database": db_status,
        "redis": redis_status,
        "status": overall_status
    })

    return {
        "status": overall_status,
        "database": db_status,
        "redis": redis_status,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


# -----------------------------
# User CRUD
# -----------------------------
@app.post("/users")
def create_user(name: str, db: Session = Depends(get_db)):
    user = User(name=name)
    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "name": user.name
    }


@app.get("/users")
def list_users(db: Session = Depends(get_db)):
    users = db.query(User).all()

    return [
        {
            "id": user.id,
            "name": user.name
        }
        for user in users
    ]

# -----------------------------
# Version / build info
# -----------------------------
@app.get("/version")
def version():
    """Returns app version and build metadata — proves CI/CD deployed new code."""
    return {
        "version": "1.1.0",
        "commit": os.getenv("BUILD_SHA", "dev"),
        "environment": os.getenv("APP_ENV", "unknown"),
    }

# -----------------------------
# Chaos / Testing endpoints
# -----------------------------
@app.get("/slow")
async def slow_endpoint():
    """Simulates a slow database query or degraded API (sleeps for 3 seconds)"""
    logger.warning("Slow endpoint triggered! Sleeping for 3 seconds...")
    await asyncio.sleep(3)
    return {"message": "That took a while!"}
@app.get("/crash")
def crash_endpoint():
    """Simulates a massive failure (throws 500 Internal Server Error)"""
    logger.error("Crash endpoint triggered! Throwing an exception...")
    raise HTTPException(status_code=500, detail="Intentional chaos triggered!")
