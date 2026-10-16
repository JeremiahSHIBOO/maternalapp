"""Configuration loaded from environment variables."""
import os
from pathlib import Path
from typing import List

BASE_DIR = Path(__file__).parent.parent.parent.parent
BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:8000")
# Supabase PostgreSQL connection string (required — no SQLite fallback).
# Format: postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres
DATABASE_URL = os.getenv("DATABASE_URL", "")
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
USERS_PER_PAGE = 20
MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/svg+xml"]
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

# Feature flags
ENABLE_AI_INSIGHTS = os.getenv("ENABLE_AI_INSIGHTS", "false").lower() == "true"
ENABLE_PARTNER_SHARING = os.getenv("ENABLE_PARTNER_SHARING", "true").lower() == "true"
ENABLE_DOCTOR_PORTAL = os.getenv("ENABLE_DOCTOR_PORTAL", "true").lower() == "true"

ADMIN_USERS = os.getenv("ADMIN_USERS", "").split(",") if os.getenv("ADMIN_USERS") else []

ALLOWED_ORIGINS = [
    o.strip() for o in os.getenv("ALLOWED_ORIGINS", "").split(",") if o.strip()
]

# Supabase Auth configuration (Flutter authenticates with Supabase; the
# Python API verifies Supabase access tokens via the project JWKS endpoint).
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")


def is_production() -> bool:
    return os.getenv("ENVIRONMENT", "development").lower() == "production"


def is_development() -> bool:
    return not is_production()