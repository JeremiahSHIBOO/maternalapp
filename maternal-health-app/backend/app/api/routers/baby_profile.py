"""Baby profile router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing: List

from ...core.database import get_db
from ...models.models import BabyProfile
from ...schemas.schemas import BabyProfileCreate, BabyProfileResponse

router = APIRouter(prefix="/baby-profile", tags=["baby-profile"])


@router.post("/", response_model=BabyProfileResponse)
async def create_baby_profile(
    profile: BabyProfileCreate,
    db: Session = Depends(get_db),
):
    """Create a new baby profile."""
    # Check if profile already exists
    existing = db.query(BabyProfile).filter(
        BabyProfile.mother_profile_id == profile.mother_profile_id
    ).first()
    
    if existing:
        # Update existing
        existing.birth_date = profile.birth_date
        existing.birth_weight = profile.birth_weight
        existing.birth_length = profile.birth_length
        existing.gender = profile.gender
        db.commit()
        db.refresh(existing)
        return existing
    else:
        new_profile = BabyProfile(**profile.dict())
        db.add(new_profile)
        db.commit()
        db.refresh(new_profile)
        return new_profile


@router.get("/", response_model=BabyProfileResponse)
async def get_baby_profile(
    mother_profile_id: int,
    db: Session = Depends(get_db),
):
    """Get baby profile for a mother."""
    profile = db.query(BabyProfile).filter(BabyProfile.mother_profile_id == mother_profile_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Baby profile not found")
    return profile