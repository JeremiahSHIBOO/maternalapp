"""Medical documents router."""
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import MedicalDocument
from ...schemas.schemas import MedicalDocumentCreate, MedicalDocumentUpdate, MedicalDocumentResponse

router = APIRouter(prefix="/medical-documents", tags=["medical-documents"])


@router.post("/", response_model=MedicalDocumentResponse)
async def upload_document(
    title: str = Form(...,
    document_type: str = Form(...,
    file: UploadFile = File(...),
    mother_profile_id: int = Form(...),
    db: Session = Depends(get_db),
):
    """Upload a medical document."""
    # Validate document type
    allowed_types = ["ultrasound", "blood_work", "nt_scan", "report", "other"]
    if document_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid document type. Allowed: {allowed_types}",
        )
    
    # In a real app, we'd save the file to storage
    # For now, we'll just record the metadata
    storage_path = f"documents/{mother_profile_id}/{file.filename}"
    
    new_document = MedicalDocument(
        title=title,
        document_type=document_type,
        storage_path=storage_path,
        uploaded_by="mother",  # Would come from auth
        mother_profile_id=mother_profile_id,
    )
    
    db.add(new_document)
    db.commit()
    db.refresh(new_document)
    return new_document


@router.get("/", response_model=List[MedicalDocumentResponse])
async def get_documents(
    mother_profile_id: int,
    db: Session = Depends(get_db),
):
    """Get all documents for a mother."""
    documents = db.query(MedicalDocument).filter(
        MedicalDocument.mother_profile_id == mother_profile_id
    ).all()
    return documents


@router.get("/{document_id}", response_model=MedicalDocumentResponse)
async def get_document(
    document_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific document."""
    document = db.query(MedicalDocument).filter(MedicalDocument.id == document_id).first()
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    return document