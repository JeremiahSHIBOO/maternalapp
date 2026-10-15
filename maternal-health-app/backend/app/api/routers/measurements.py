"""Manual measurements router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...models.models import ManualMeasurement
from ...schemas.schemas import ManualMeasurementCreate, ManualMeasurementUpdate, ManualMeasurementResponse

router = APIRouter(prefix="/measurements", tags=["measurements"])


@router.post("/", response_model=ManualMeasurementResponse)
async def create_measurement(
    measurement: ManualMeasurementCreate,
    db: Session = Depends(get_db),
):
    """Create a new manual measurement."""
    # Mark demo measurements
    if measurement.source == "demo":
        measurement.is_demo = True
    
    new_measurement = ManualMeasurement(**measurement.dict())
    db.add(new_measurement)
    db.commit()
    db.refresh(new_measurement)
    return new_measurement


@router.get("/", response_model=List[ManualMeasurementResponse])
async def get_measurements(
    db: Session = Depends(get_db),
):
    """Get all measurements."""
    measurements = db.query(ManualMeasurement).all()
    return measurements


@router.get("/{measurement_id}", response_model=ManualMeasurementResponse)
async def get_measurement(
    measurement_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific measurement."""
    measurement = db.query(ManualMeasurement).filter(
        ManualMeasurement.id == measurement_id
    ).first()
    if not measurement:
        raise HTTPException(status_code=404, detail="Measurement not found")
    return measurement


@router.put("/{measurement_id}", response_model=ManualMeasurementResponse)
async def update_measurement(
    measurement_id: int,
    measurement_update: ManualMeasurementUpdate,
    db: Session = Depends(get_db),
):
    """Update a measurement."""
    measurement = db.query(ManualMeasurement).filter(
        ManualMeasurement.id == measurement_id
    ).first()
    if not measurement:
        raise HTTPException(status_code=404, detail="Measurement not found")
    
    update_data = measurement_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(measurement, field, value)
    
    db.commit()
    db.refresh(measurement)
    return measurement