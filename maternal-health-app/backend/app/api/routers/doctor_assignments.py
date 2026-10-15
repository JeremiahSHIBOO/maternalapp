"""Doctor-patient assignment router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from ...core.database import get_db
from ...models.models import DoctorAssignment
from ...schemas.schemas import DoctorAssignmentCreate, DoctorAssignmentResponse

router = APIRouter(prefix="/doctor-assignments", tags=["doctor-assignments"])


@router.post("/", response_model=DoctorAssignmentResponse)
async def assign_doctor(
    assignment: DoctorAssignmentCreate,
    db: Session = Depends(get_db),
):
    """Assign a doctor to a mother's profile."""
    # Check if assignment already exists
    existing = db.query(DoctorAssignment).filter(
        DoctorAssignment.mother_profile_id == assignment.mother_profile_id
    ).first()
    
    if existing:
        # Update existing
        existing.doctor_user_id = assignment.doctor_user_id
        existing.is_primary = assignment.is_primary
        db.commit()
        db.refresh(existing)
        return existing
    else:
        new_assignment = DoctorAssignment(**assignment.dict())
        db.add(new_assignment)
        db.commit()
        db.refresh(new_assignment)
        return new_assignment


@router.get("/", response_model=List[DoctorAssignmentResponse])
async def get_doctor_assignments(
    db: Session = Depends(get_db),
):
    """Get all doctor assignments."""
    assignments = db.query(DoctorAssignment).all()
    return assignments