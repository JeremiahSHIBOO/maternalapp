"""FastAPI application entry point."""
import uvicorn

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .core.config import (
    BASE_URL,
    ENVIRONMENT,
    is_development,
    is_production,
)
from .core.database import get_db
from .api.router import api_router

app = FastAPI(
    title="Maternal Health Companion API",
    description="Connected care platform for Mother, Partner, and Healthcare Provider",
    version="1.0.0",
    docs_url="/docs" if is_development() else None,
    redoc_url="/redoc" if is_development() else None,
)

# CORS configuration for local development
if is_development():
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://127.0.0.1:8000",
            "http://localhost:8000",
            "http://127.0.0.1:3000",
            "http://localhost:3000",
            "http://127.0.0.1:8501",
            "http://localhost:8501",
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Include API router
app.include_router(api_router, prefix="/api")


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {"message": "Maternal Health Companion API", "version": "1.0.0"}


@app.get("/health", include_in_schema=True)
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "maternal-health-api"}


@app.exception_handler(404)
async def not_found_error_handler(request: Request, exc):
    """Global 404 handler."""
    return JSONResponse(
        status_code=404,
        content={"detail": "Not found"},
    )


@app.exception_handler(500)
async def internal_error_handler(request: Request, exc):
    """Global 500 handler."""
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=is_development(),
    )
# TODO: init_db() - enable when PostgreSQL is available
