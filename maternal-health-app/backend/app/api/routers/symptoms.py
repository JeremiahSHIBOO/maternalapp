"""Symptoms router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import SymptomLog
from ...schemas.schemas import SymptomLogCreate, SymptomLogUpdate, SymptomLogResponse

router = APIRouter(prefix="/symptoms", tags=["symptoms"])


@router.post("/", response_model=SymptomLogResponse)
async def create_symptom_log(
    symptom: SymptomLogCreate,
    db: Session = Depends(get_db),
):
    """Create a new symptom log entry."""
    new_symptom = SymptomLog(**symptom.dict())
    db.add(new_symptom)
    db.commit()
    db.refresh(new_symptom)
    return new_symptom


@router.get("/", response_model=List[SymptomLogResponse])
async def get_symptom_logs(
    db: Session = Depends(get_db),
):
    """Get all symptom logs."""
    symptoms = db.query(SymptomLog).all()
    return symptoms


@router.get("/{symptom_id}", response_model=SymptomLogResponse)
async def get_symptom_log(
    symptom_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific symptom log."""
    symptom = db.query(SymptomLog).filter(SymptomLog.id == symptom_id).first()
    if not symptom:
        raise HTTPException(status_code=404, detail="Symptom log not found")
    return symptom


@router.put("/{symptom_id}", response_model=SymptomLogResponse)
async def update_symptom_log(
    symptom_id: int,
    symptom_update: SymptomLogUpdate,
    db: Session = Depends(get_db),
):
    """Update a symptom log."""
    symptom = db.query(SymptomLog).filter(SymptomLog.id == symptom_id).first()
    if not symptom:
        raise HTTPException(status_code=404, detail="Symptom log not found")
    
    update_data = symptom_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(symptom, field, value)
    
    db.commit()
    db.refresh(symptom)
    return symptom