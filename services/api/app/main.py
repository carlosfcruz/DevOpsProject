from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime
import os
import psycopg2
import redis

from app.database import engine, SessionLocal
from app.models import Base, User

# Create FastAPI instance
app = FastAPI()

# Create tables automatically (development only)
Base.metadata.create_all(bind=engine)


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
        "app_name": "platform",
        "environment": os.getenv("APP_ENV"),
        "status": "running"
    }


# -----------------------------
# Health check helpers
# -----------------------------
def check_database():
    try:
        connection = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
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

    return {
        "status": overall_status,
        "database": db_status,
        "redis": redis_status,
        "timestamp": datetime.utcnow().isoformat()
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
