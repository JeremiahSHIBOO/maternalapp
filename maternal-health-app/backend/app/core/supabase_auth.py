"""Supabase JWT verification for the wellness API.

Verifies access tokens issued by Supabase Auth using the project's JWKS
endpoint, so the Flutter app can keep using Supabase auth unchanged. In
development, a locally-signed HS256 token (created with the app's own
SECRET_KEY) is also accepted so the API can be tested without Supabase.
"""
from __future__ import annotations

import time
from typing import Any, Dict, Optional

import httpx
from jose import JWTError, jwk, jwt
from jose.exceptions import JOSEError

from .config import ALGORITHM, SECRET_KEY, SUPABASE_URL, is_development

_JWKS_CACHE: Optional[Dict[str, Any]] = None
_JWKS_FETCH_AT: float = 0.0
_JWKS_TTL_SECONDS = 3600


async def fetch_jwks() -> Dict[str, Any]:
    """Fetch and cache the Supabase JWKS document."""
    global _JWKS_CACHE, _JWKS_FETCH_AT
    now = time.time()
    if (
        _JWKS_CACHE is not None
        and now - _JWKS_FETCH_AT < _JWKS_TTL_SECONDS
    ):
        return _JWKS_CACHE
    if not SUPABASE_URL:
        raise RuntimeError("SUPABASE_URL is not configured")
    jwks_url = f"{SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(jwks_url)
        resp.raise_for_status()
        _JWKS_CACHE = resp.json()
        _JWKS_FETCH_AT = now
        return _JWKS_CACHE


def _signing_key(jwks: Dict[str, Any], kid: str):
    for key in jwks.get("keys", []):
        if key.get("kid") == kid:
            return jwk.construct(key)
    return None


async def verify_supabase_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify a Supabase access token and return its claims, or None."""
    try:
        unverified = jwt.get_unverified_header(token)
    except JOSEError:
        return None
    kid = unverified.get("kid")
    if not kid:
        return None
    try:
        jwks = await fetch_jwks()
    except Exception:
        return None
    key = _signing_key(jwks, kid)
    if key is None:
        return None
    try:
        issuer = f"{SUPABASE_URL.rstrip('/')}/auth/v1"
        claims = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            issuer=issuer,
            options={"verify_aud": False},
        )
        return claims  # type: ignore[no-any-return]
    except JOSEError:
        return None


def verify_local_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify a locally-signed HS256 token (development/testing only)."""
    if not is_development():
        return None
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


async def verify_bearer_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify a bearer token, trying Supabase first then local (dev)."""
    claims = await verify_supabase_token(token)
    if claims is not None:
        return claims
    return verify_local_token(token)
