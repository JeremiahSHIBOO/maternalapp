"""Database module with SQLAlchemy setup.

Connects to Supabase PostgreSQL exclusively. No SQLite fallback.
Schema is managed by `maternal-health-app/supabase/schema.sql` — this module
only creates the engine and session factory.
"""
import os
from typing import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

# All SQLAlchemy models inherit from a single Base defined in app.models.base
from ..models.base import Base  # noqa: E402

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL must be set to your Supabase PostgreSQL connection string "
        "(e.g. postgresql://postgres:password@db.<ref>.supabase.co:5432/postgres)"
    )

# Convert Supabase-style postgres:// to postgresql:// for SQLAlchemy + psycopg2
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # recover from dropped Supabase connections
    pool_size=5,
    max_overflow=10,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    """Dependency to get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Verify database connectivity.

    Does NOT create tables — Supabase schema is managed by
    `maternal-health-app/supabase/schema.sql`. This is a lightweight
    connection check used at startup.
    """
    from sqlalchemy import text

    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
