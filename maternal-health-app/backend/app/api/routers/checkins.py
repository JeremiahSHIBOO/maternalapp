"""Daily check-ins router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import DailyCheckIn
from ...schemas.schemas import DailyCheckInCreate, DailyCheckInUpdate, DailyCheckInResponse

router = APIRouter(prefix="/checkins", tags=["checkins"])


@router.post("/", response_model=DailyCheckInResponse)
async def create_check_in(
    check_in: DailyCheckInCreate,
    db: Session = Depends(get_db),
):
    """Create a new daily check-in."""
    new_check_in = DailyCheckIn(**check_in.dict())
    db.add(new_check_in)
    db.commit()
    db.refresh(new_check_in)
    return new_check_in


@router.get("/", response_model=List[DailyCheckInResponse])
async def get_check_ins(
    db: Session = Depends(get_db),
):
    """Get all check-ins."""
    check_ins = db.query(DailyCheckIn).all()
    return check_ins


@router.get("/{check_in_id}", response_model=DailyCheckInResponse)
async def get_check_in(
    check_in_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific check-in."""
    check_in = db.query(DailyCheckIn).filter(DailyCheckIn.id == check_in_id).first()
    if not check_in:
        raise HTTPException(status_code=404, detail="Check-in not found")
    return check_in


@router.put("/{check_in_id}", response_model=DailyCheckInResponse)
async def update_check_in(
    check_in_id: int,
    check_in_update: DailyCheckInUpdate,
    db: Session = Depends(get_db),
):
    """Update a check-in."""
    check_in = db.query(DailyCheckIn).filter(DailyCheckIn.id == check_in_id).first()
    if not check_in:
        raise HTTPException(status_code=404, detail="Check-in not found")
    
    update_data = check_in_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(check_in, field, value)
    
    db.commit()
    db.refresh(check_in)
    return check_in