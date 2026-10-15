"""FastAPI API router - domain-separated routers."""
from fastapi import APIRouter

api_router = APIRouter(prefix="/api")

# Domain routers - will be imported and included here
# from .routers import users, pregnancy, checkins, symptoms, measurements
# from .routers import appointments, tasks, expenses, consent, documents
# from .routers import clinician_notes, postpartum, baby_care, notifications, insights

# TODO: Include domain routers when created
# api_router.include_router(users.router, prefix="/users", tags=["users"])
# api_router.include_router(pregnancy.router, prefix="/pregnancy", tags=["pregnancy"])
# etc.