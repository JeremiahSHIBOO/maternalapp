"""Baby care events router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing: List

from ...core.database import get_db
from ...models.models import BabyCareEvent
from ...schemas.schemas import BabyCareEventCreate, BabyCareEventUpdate, BabyCareEventResponse

router = APIRouter(prefix="/baby-care-events", tags=["baby-care-events"])


@router.post("/", response_model=BabyCareEventResponse)
async def create_baby_care_event(
    event: BabyCareEventCreate,
    db: Session = Depends(get_db),
):
    """Create a new baby care event."""
    new_event = BabyCareEvent(**event.dict())
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    return new_event


@router.get("/", response_model=List[BabyCareEventResponse])
async def get_baby_care_events(
    mother_profile_id: int,
    db: Session = Depends(get_db),
):
    """Get all baby care events for a mother."""
    events = db.query(BabyCareEvent).filter(
        BabyCareEvent.mother_profile_id == mother_profile_id
    ).all()
    return events


@router.get("/{event_id}", response_model=BabyCareEventResponse)
async def get_baby_care_event(
    event_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific baby care event."""
    event = db.query(BabyCareEvent).filter(BabyCareEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Baby care event not found")
    return event