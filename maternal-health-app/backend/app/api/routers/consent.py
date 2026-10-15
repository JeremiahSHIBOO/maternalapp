"""Consent/permissions router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...core.database import get_db
from ...models.models import ConsentGrant
from ...schemas.schemas import ConsentGrantCreate, ConsentGrantUpdate, ConsentGrantResponse

router = APIRouter(prefix="/consent", tags=["consent"])


@router.post("/", response_model=ConsentGrantResponse)
async def grant_consent(
    consent: ConsentGrantCreate,
    db: Session = Depends(get_db),
):
    """Grant consent/permissions."""
    # Check if consent already exists for this mother and role
    existing = db.query(ConsentGrant).filter(
        ConsentGrant.mother_profile_id == consent.mother_profile_id,
        ConsentGrant.granted_to_role == consent.granted_to_role,
    ).first()
    
    if existing:
        # Update existing - revoke old and create new
        existing.revoked_at = datetime.now(timezone.utc)
        existing.granted_scope = consent.granted_scope
        existing.granted_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(existing)
        return existing
    else:
        new_consent = ConsentGrant(**consent.dict())
        db.add(new_consent)
        db.commit()
        db.refresh(new_consent)
        return new_consent


@router.get("/", response_model=List[ConsentGrantResponse])
async def get_consent_grants(
    db: Session = Depends(get_db),
):
    """Get all consent grants."""
    consents = db.query(ConsentGrant).all()
    return consents


@router.patch("/{consent_id}", response_model=ConsentGrantResponse)
async def revoke_consent(
    consent_id: int,
    db: Session = Depends(get_db),
):
    """Revoke consent/permissions."""
    consent = db.query(ConsentGrant).filter(ConsentGrant.id == consent_id).first()
    if not consent:
        raise HTTPException(status_code=404, detail="Consent grant not found")
    
    consent.revoked_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(consent)
    return consent