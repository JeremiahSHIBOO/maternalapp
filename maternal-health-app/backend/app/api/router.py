"""FastAPI API router - domain-separated routers."""
from fastapi import APIRouter

# No prefix here: the single "/api" prefix is applied in main.py when the
# router is mounted. Domain routers carry their own path prefix.
api_router = APIRouter()

from .routers import users, checkins, insights, measurements  # noqa: E402
from .routers import wellness  # noqa: E402

api_router.include_router(users.router, tags=["users"])
api_router.include_router(checkins.router, tags=["checkins"])
api_router.include_router(insights.router, tags=["insights"])
api_router.include_router(measurements.router, tags=["measurements"])
api_router.include_router(wellness.router, tags=["wellness"])
