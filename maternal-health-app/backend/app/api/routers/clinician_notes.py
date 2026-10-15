"""Clinician notes router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import ClinicianNote
from ...schemas.schemas import ClinicianNoteCreate, ClinicianNoteUpdate, ClinicianNoteResponse

router = APIRouter(prefix="/clinician-notes", tags=["clinician-notes"])


@router.post("/", response_model=ClinicianNoteResponse)
async def create_clinician_note(
    note: ClinicianNoteCreate,
    db: Session = Depends(get_db),
):
    """Create a new clinician note."""
    new_note = ClinicianNote(
        mother_profile_id=note.mother_profile_id,
        doctor_user_id=note.doctor_user_id,
        title=note.title,
        observations=note.observations,
        prescriptions=note.prescriptions,
    )
    db.add(new_note)
    db.commit()
    db.refresh(new_note)
    return new_note


@router.get("/", response_model=List[ClinicianNoteResponse])
async def get_clinician_notes(
    mother_profile_id: int,
    db: Session = Depends(get_db),
):
    """Get all clinician notes for a mother."""
    notes = db.query(ClinicianNote).filter(
        ClinicianNote.mother_profile_id == mother_profile_id
    ).all()
    return notes


@router.get("/{note_id}", response_model=ClinicianNoteResponse)
async def get_clinician_note(
    note_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific clinician note."""
    note = db.query(ClinicianNote).filter(ClinicianNote.id == note_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Clinician note not found")
    return note