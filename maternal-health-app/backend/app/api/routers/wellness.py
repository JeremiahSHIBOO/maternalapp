"""Wellness check-ins, insights, and prediction router."""
from __future__ import annotations
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ...core.database import get_db
from ...api.dependencies import get_current_user
from ...models.models import DailyCheckIn, MotherPregnancyProfile
from ...schemas.wellness import (
    WellnessCheckInCreate,
    WellnessCheckInResponse,
    TodayInsightsResponse,
    HistoricalTrendsResponse,
    MLPredictionResponse,
)
from ...insights import InsightsEngine
from ...history import analyze_history
from ...ml_model import EnergyPredictor

router = APIRouter(prefix="/wellness", tags=["wellness"])

predictor = EnergyPredictor()
predictor.load()


def _get_user_mother_profile(db: Session, user: dict) -> MotherPregnancyProfile:
    profile = (
        db.query(MotherPregnancyProfile)
        .filter(MotherPregnancyProfile.user_id == user["id"])
        .first()
    )
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pregnancy profile not found for user.",
        )
    return profile


def _check_in_dict(record: DailyCheckIn) -> Dict[str, Any]:
    return {
        "sleep_duration_hours": record.sleep_duration_hours,
        "sleep_quality": record.sleep_quality,
        "mood": record.mood,
        "energy": record.energy,
        "stress": record.stress,
        "hydration": record.hydration_status,
        "notes": record.notes,
        "check_in_date": record.check_in_date,
        "created_at": record.created_at,
    }


@router.post("/check-ins", response_model=WellnessCheckInResponse)
async def create_check_in(
    payload: WellnessCheckInCreate,
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    """Validate, store, and analyze a submitted wellness check-in.

    The authenticated user's id (from the JWT) is used; a client-supplied user
    id is never trusted as proof of identity.
    """
    profile = _get_user_mother_profile(db, user)
    user_id = str(profile.id)

    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    existing: Optional[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(
            DailyCheckIn.mother_profile_id == profile.id,
            DailyCheckIn.check_in_date >= today_start,
            DailyCheckIn.check_in_date < today_end,
        )
        .order_by(DailyCheckIn.check_in_date.desc())
        .first()
    )

    check_in = existing or DailyCheckIn(mother_profile_id=profile.id)
    check_in.sleep_duration_hours = payload.sleep_duration_hours
    check_in.sleep_quality = payload.sleep_quality
    check_in.mood = payload.mood
    check_in.energy = payload.energy
    check_in.stress = payload.stress
    check_in.hydration_status = payload.hydration
    check_in.notes = payload.notes
    check_in.created_at = now

    if existing is None:
        db.add(check_in)
    db.commit()
    db.refresh(check_in)

    # History for insights (all prior check-ins, oldest first)
    history_rows: List[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(DailyCheckIn.mother_profile_id == profile.id)
        .order_by(DailyCheckIn.check_in_date.asc())
        .all()
    )
    history = [_check_in_dict(r) for r in history_rows]

    engine = InsightsEngine(history=history[:-1] if history else [])
    analysis = engine.analyze(_check_in_dict(check_in), user_id=user_id)

    ml = predictor.predict(_check_in_dict(check_in))

    return WellnessCheckInResponse(
        status="ok",
        created_at=check_in.created_at,
        check_in_id=check_in.id,
        user_id=user_id,
        insights=analysis["insights"],
        suggestions=analysis["suggestions"],
        historical_trends=analysis["historical_trends"],
        sample_size=analysis["sample_size"],
        model_prediction=ml,
    )


@router.get("/insights/today", response_model=TodayInsightsResponse)
async def insights_today(
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    profile = _get_user_mother_profile(db, user)
    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    today_end = today_start + timedelta(days=1)

    latest: Optional[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(
            DailyCheckIn.mother_profile_id == profile.id,
            DailyCheckIn.check_in_date >= today_start,
            DailyCheckIn.check_in_date < today_end,
        )
        .order_by(DailyCheckIn.check_in_date.desc())
        .first()
    )

    if not latest:
        return TodayInsightsResponse(
            status="ok",
            created_at=datetime.now(timezone.utc),
            insights=[],
            suggestions=[],
            sample_size=0,
        )

    history_rows: List[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(DailyCheckIn.mother_profile_id == profile.id)
        .order_by(DailyCheckIn.check_in_date.asc())
        .all()
    )
    history = [_check_in_dict(r) for r in history_rows]
    engine = InsightsEngine(history=history[:-1] if history else [])
    analysis = engine.analyze(_check_in_dict(latest), user_id=str(profile.id))

    return TodayInsightsResponse(
        status="ok",
        created_at=latest.created_at,
        insights=analysis["insights"],
        suggestions=analysis["suggestions"],
        sample_size=analysis["sample_size"],
    )


@router.get("/insights/history", response_model=HistoricalTrendsResponse)
async def insights_history(
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    profile = _get_user_mother_profile(db, user)
    rows: List[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(DailyCheckIn.mother_profile_id == profile.id)
        .order_by(DailyCheckIn.check_in_date.asc())
        .all()
    )
    records = [_check_in_dict(r) for r in rows]
    trends = analyze_history(records, user_id=str(profile.id))
    return HistoricalTrendsResponse(
        status="ok",
        user_id=trends["user_id"],
        seven_day=trends["seven_day"],
        thirty_day=trends["thirty_day"],
        sample_size=trends["sample_size"],
        associations=trends["associations"],
        missing_data_rates=trends["missing_data_rates"],
    )


@router.get("/insights/predict", response_model=MLPredictionResponse)
async def predict_energy(
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    profile = _get_user_mother_profile(db, user)
    rows: List[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(DailyCheckIn.mother_profile_id == profile.id)
        .order_by(DailyCheckIn.check_in_date.asc())
        .all()
    )
    if not rows:
        return MLPredictionResponse(
            status="ok",
            model_available=False,
            fallback=True,
            message="No check-in history available.",
        )
    latest = rows[-1]
    ml = predictor.predict(_check_in_dict(latest))
    return MLPredictionResponse(status="ok", **ml)


@router.post("/ml/train")
async def train_ml_model(
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    """Train (or retrain) the next-day energy prediction model.

    Uses the authenticated user's historical check-ins. Trains only when the
    minimum record threshold is met; otherwise returns the current fallback
    status. This endpoint is for demonstration — in production, training
    should be triggered by a background job once sufficient real data exists.
    """
    profile = _get_user_mother_profile(db, user)
    rows: List[DailyCheckIn] = (
        db.query(DailyCheckIn)
        .filter(DailyCheckIn.mother_profile_id == profile.id)
        .order_by(DailyCheckIn.check_in_date.asc())
        .all()
    )
    records = [_check_in_dict(r) for r in rows]

    result = predictor.train(records)
    return {
        "status": "ok" if result.get("trained") else "not_trained",
        "user_id": str(profile.id),
        **result,
    }
