"""Insights router - AI-generated summaries."""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import InsightSummary
from ...schemas.schemas import InsightSummaryCreate, InsightSummaryResponse

router = APIRouter(prefix="/insights", tags=["insights"])


@router.post("/", response_model=InsightSummaryResponse)
async def create_insight_summary(
    insight: InsightSummaryCreate,
    db: Session = Depends(get_db),
):
    """Create a new insight summary."""
    # Check if insight already exists for this period
    existing = db.query(InsightSummary).filter(
        InsightSummary.mother_profile_id == insight.mother_profile_id,
    ).first()
    
    if existing:
        # Update existing
        existing.summary_text = insight.summary_text
        existing.generated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(existing)
        return existing
    else:
        new_insight = InsightSummary(**insight.dict())
        db.add(new_insight)
        db.commit()
        db.refresh(new_insight)
        return new_insight


@router.get("/", response_model=List[InsightSummaryResponse])
async def get_insight_summaries(
    mother_profile_id: int,
    db: Session = Depends(get_db),
):
    """Get all insight summaries for a mother."""
    summaries = db.query(InsightSummary).filter(
        InsightSummary.mother_profile_id == mother_profile_id
    ).all()
    return summaries