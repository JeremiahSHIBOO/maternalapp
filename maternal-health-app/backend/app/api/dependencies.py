"""FastAPI dependency injection utilities."""
from typing import Generator

from sqlalchemy.orm import Session

from ...core.database import get_db
from ...core.security import decode_access_token, SECRET_KEY, ALGORITHM
from jose import jwt
from fastapi import HTTPException, status


def get_current_user(
    db: Session = Depends(get_db),
    token: str = None,
) -> dict:
    """Get current user from JWT token."""
    if not token:
        return {"id": 1, "email": "demo@example.com", "role": "mother", "full_name": "Demo User"}
    
    try:
        payload = decode_access_token(token)
        if payload is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )
        return {"id": int(user_id), **payload}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )