"""FastAPI dependency injection utilities."""
from typing import Generator

from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from ..core.database import get_db
from ..core.supabase_auth import verify_bearer_token

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    db: Session = Depends(get_db),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict:
    """Get current user from a verified bearer token.

    Verifies Supabase access tokens (issued when the Flutter app signs in with
    Supabase). In development, locally-signed HS256 tokens are also accepted.
    Never falls back to a demo user.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        claims = await verify_bearer_token(credentials.credentials)
    except Exception:
        claims = None
    if claims is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id: str = claims.get("sub") or claims.get("user_id")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"id": int(user_id), **claims}
