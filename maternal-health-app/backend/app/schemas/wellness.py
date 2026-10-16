"""Pydantic schemas for wellness check-ins and insights."""
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, confloat


class HealthReading(BaseModel):
    """Optional health reading with value, unit, and timestamp."""
    measurement_type: str = Field(
        ..., description="e.g. blood_pressure_systolic, heart_rate"
    )
    value: Optional[confloat(ge=0)] = Field(
        None, ge=0, description="Numeric reading value"
    )
    unit: Optional[str] = Field(None, description="e.g. mmHg, bpm, kg")
    timestamp: Optional[datetime] = Field(
        None, description="When the reading was taken"
    )

    class Config:
        from_attributes = True


class WellnessCheckInCreate(BaseModel):
    """Request: submitted wellness check-in values from the Flutter form."""

    sleep_duration_hours: Optional[confloat(ge=0, le=24)] = Field(
        None, description="Hours slept"
    )
    sleep_quality: Optional[str] = Field(
        None, description="Poor, Okay, Good"
    )
    mood: Optional[str] = Field(None, description="Low, Okay, Good")
    energy: Optional[str] = Field(None, description="Low, Some, Plenty")
    stress: Optional[str] = Field(None, description="Low, Some, High")
    hydration: Optional[str] = Field(
        None, description="poor, fair, good, excellent"
    )
    notes: Optional[str] = Field(
        None, max_length=2000, description="Optional free-text notes"
    )
    health_readings: Optional[List[HealthReading]] = Field(
        None, max_length=20, description="Optional measured readings"
    )

    class Config:
        from_attributes = True


class WellnessCheckInResponse(BaseModel):
    """Response: stored check-in plus generated insights."""

    status: str
    created_at: datetime
    check_in_id: int
    user_id: str
    insights: List[Dict[str, Any]]
    suggestions: List[str]
    historical_trends: Optional[Dict[str, Any]] = None
    sample_size: Optional[int] = None
    model_prediction: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


class InsightItem(BaseModel):
    type: str
    message: str
    supporting_observations: List[Dict[str, Any]] = []
    suggested_action: Optional[str] = None
    severity: Optional[str] = Field(
        None, description="info, low, medium, high"
    )

    class Config:
        from_attributes = True


class TodayInsightsResponse(BaseModel):
    status: str
    created_at: datetime
    insights: List[InsightItem]
    suggestions: List[str]
    sample_size: Optional[int] = None

    class Config:
        from_attributes = True


class HistoricalTrendsResponse(BaseModel):
    status: str
    user_id: str
    seven_day: Optional[Dict[str, Any]] = None
    thirty_day: Optional[Dict[str, Any]] = None
    sample_size: int
    associations: List[Dict[str, Any]] = []
    missing_data_rates: Dict[str, float] = {}

    class Config:
        from_attributes = True


class MLPredictionResponse(BaseModel):
    status: str
    prediction: Optional[str] = None
    probability: Optional[float] = None
    model_available: bool
    fallback: bool
    message: str

    class Config:
        from_attributes = True
