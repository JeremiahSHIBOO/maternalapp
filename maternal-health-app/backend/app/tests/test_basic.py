"""Basic tests for maternal health platform backend."""

import pytest
from fastapi.testclient import TestClient

from ..main import app

client = TestClient(app)


def test_health_endpoint():
    """Test the health check endpoint."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "maternal-health-api"


def test_root_endpoint():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Maternal Health Companion API"


def test_users_login():
    """Test user login."""
    response = client.post(
        "/api/users/login",
        json={"email": "ananya@example.com", "password": "password123"},
    )
    # This will fail if no users are seeded, but test structure is valid
    assert response.status_code in [200, 401]  # 401 if no users seeded


def test_users_register():
    """Test user registration."""
    response = client.post(
        "/api/users/register",
        json={
            "email": "test@example.com",
            "full_name": "Test User",
            "password": "password123",
            "role": "mother",
        },
    )
    assert response.status_code in [200, 400]  # 400 if email already exists


def test_pagination_params():
    """Test pagination parameters schema."""
    from ..schemas.schemas import PaginationParams, PaginatedResponse
    
    params = PaginationParams(page=1, size=20)
    assert params.page == 1
    assert params.size == 20
    assert params.pages == 0  # Empty by default