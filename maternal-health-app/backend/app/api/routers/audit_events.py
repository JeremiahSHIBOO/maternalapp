"""Audit events router - sensitive access and permission changes."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing: List

from ...core.database import get_db
from ...models.models import AuditEvent
from ...schemas.schemas import AuditEventCreate, AuditEventResponse

router = APIRouter(prefix="/audit-events", tags=["audit-events"])


@router.post("/", response_model=AuditEventResponse)
async def create_audit_event(
    audit: AuditEventCreate,
    db: Session = Depends(get_db),
):
    """Create a new audit event log entry."""
    new_audit = AuditEvent(**audit.dict())
    db.add(new_audit)
    db.commit()
    db.refresh(new_audit)
    return new_audit


@router.get("/", response_model=List[AuditEventResponse])
async def get_audit_events(
    db: Session = Depends(get_db),
    limit: int = 100,
):
    """Get audit event log."""
    events = db.query(AuditEvent).order_by(AuditEvent.created_at.desc()).limit(limit).all()
    return events