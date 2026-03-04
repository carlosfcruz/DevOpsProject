import asyncio
import logging
import os
import platform
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

import psycopg2
import redis
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import HTMLResponse
from prometheus_fastapi_instrumentator import Instrumentator
from pythonjsonlogger import jsonlogger
from sqlalchemy.orm import Session
from starlette.staticfiles import StaticFiles

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

# -----------------------------
# App initialization
# -----------------------------
app = FastAPI(lifespan=lifespan)
Instrumentator().instrument(app).expose(app)
APP_START_TIME = datetime.now(timezone.utc)
app.mount("/static", StaticFiles(directory=Path(__file__).parent / "static"), name="static")

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
    return {
        "version": "1.1.0",
        "commit": os.getenv("BUILD_SHA", "dev"),
        "environment": os.getenv("APP_ENV", "unknown"),
    }

# -----------------------------
# Dashboard & Status API
# -----------------------------
@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard():
    html_path = Path(__file__).parent / "static" / "dashboard.html"
    return HTMLResponse(content=html_path.read_text())


@app.get("/api/status")
def api_status():
    db_status = check_database()
    redis_status = check_redis()
    uptime = (datetime.now(timezone.utc) - APP_START_TIME).total_seconds()

    return {
        "app": {
            "name": os.getenv("APP_NAME", "platform"),
            "version": "1.1.0",
            "commit": os.getenv("BUILD_SHA", "dev"),
            "environment": os.getenv("APP_ENV", "unknown"),
            "uptime_seconds": round(uptime, 1)
        },
        "health": {
            "database": db_status,
            "redis": redis_status,
            "overall": "ok" if db_status == "ok" and redis_status == "ok" else "degraded"
        },
        "system": {
            "hostname": platform.node(),
            "python_version": platform.python_version(),
            "platform": platform.platform()
        },
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


@app.get("/api/stats")
def api_stats(db: Session = Depends(get_db)):
    user_count = db.query(User).count()

    try:
        r = redis.Redis(host=os.getenv("REDIS_HOST"), port=6379)
        start = time.time()
        r.ping()
        redis_ping_ms = round((time.time() - start) * 1000, 2)
    except Exception:
        redis_ping_ms = -1

    return {
        "user_count": user_count,
        "redis_ping_ms": redis_ping_ms,
        "timestamp": datetime.now(timezone.utc).isoformat()
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
