"""Pregnancy router - pregnancy profile and timeline."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...core.database import get_db
from ...models.models import MotherPregnancyProfile, BabyGrowthWeek
from ...schemas.schemas import (
    MotherPregnancyProfileResponse, MotherPregnancyProfileCreate,
    MotherPregnancyProfileUpdate, BabyGrowthWeekResponse,
    BabyGrowthWeekCreate
)
from pydantic import EmailStr

router = APIRouter(prefix="/pregnancy", tags=["pregnancy"])


@router.get("/profile", response_model=MotherPregnancyProfileResponse)
async def get_pregnancy_profile(
    db: Session = Depends(get_db),
):
    """Get mother's pregnancy profile."""
    profile = db.query(MotherPregnancyProfile).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Pregnancy profile not found")
    return profile


@router.post("/profile", response_model=MotherPregnancyProfileResponse)
async def create_pregnancy_profile(
    profile_data: MotherPregnancyProfileCreate,
    db: Session = Depends(get_db),
):
    """Create or update pregnancy profile."""
    existing = db.query(MotherPregnancyProfile).filter(
        MotherPregnancyProfile.user_id == profile_data.user_id
    ).first()
    
    if existing:
        # Update existing
        existing.lmp_date = profile_data.lmp_date
        existing.edd_date = profile_data.edd_date
        existing.conception_date = profile_data.conception_date
        existing.current_gestational_weeks = profile_data.current_gestational_weeks
        existing.trimester = profile_data.trimester
        existing.pregnancy_type = profile_data.pregnancy_type
        existing.notes = profile_data.notes
        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new
        new_profile = MotherPregnancyProfile(**profile_data.dict())
        db.add(new_profile)
        db.commit()
        db.refresh(new_profile)
        return new_profile


@router.get("/timeline", response_model=List[BabyGrowthWeekResponse])
async def get_baby_growth_timeline(
    db: Session = Depends(get_db),
):
    """Get baby growth week timeline."""
    weeks = db.query(BabyGrowthWeek).all()
    return weeks


@router.get("/timeline/{week_number}", response_model=BabyGrowthWeekResponse)
async def get_baby_growth_week(
    week_number: int,
    db: Session = Depends(get_db),
):
    """Get specific baby growth week content."""
    week = db.query(BabyGrowthWeek).filter(BabyGrowthWeek.week_number == week_number).first()
    if not week:
        raise HTTPException(status_code=404, detail=f"Week {week_number} not found")
    return week


@router.post("/timeline", response_model=BabyGrowthWeekResponse)
async def create_baby_growth_week(
    week_data: BabyGrowthWeekCreate,
    db: Session = Depends(get_db),
):
    """Add baby growth week content."""
    # Check if week already exists
    existing = db.query(BabyGrowthWeek).filter(
        BabyGrowthWeek.pregnancy_profile_id == week_data.pregnancy_profile_id,
        BabyGrowthWeek.week_number == week_data.week_number,
    ).first()
    
    if existing:
        # Update existing
        existing.illustration_identifier = week_data.illustration_identifier
        existing.fruit_vegetable_comparison = week_data.fruit_vegetable_comparison
        existing.size_cm = week_data.size_cm
        existing.weight_g = week_data.weight_g
        existing.educational_summary = week_data.educational_summary
        existing.source = week_data.source
        existing.review_date = week_data.review_date
        existing.clinical_review_status = week_data.clinical_review_status
        existing.doctor_questions = week_data.doctor_questions
        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new
        new_week = BabyGrowthWeek(**week_data.dict())
        db.add(new_week)
        db.commit()
        db.refresh(new_week)
        return new_week