"""Pydantic schemas for maternal health platform API."""

from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, confloat, conint


# --- Authentication ---

class Token(BaseModel):
    """JWT token response."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(default=1800)  # 30 minutes


class TokenData(BaseModel):
    """Decoded token data."""
    sub: Optional[str] = None
    role: Optional[str] = None


class LoginRequest(BaseModel):
    """Login request."""
    email: EmailStr = Field(..., description="User email")
    password: str = Field(..., description="User password")


class RegisterRequest(BaseModel):
    """User registration request."""
    email: EmailStr = Field(..., description="User email")
    full_name: str = Field(..., description="Full name")
    password: str = Field(..., min_length=8, description="Password")
    role: str = Field("mother", description="User role: mother, partner, doctor")


# --- User ---

class UserBase(BaseModel):
    """Base user fields."""
    email: EmailStr = Field(..., description="User email")
    full_name: str = Field(..., min_length=1, description="Full name")
    role: str = Field(..., description="User role")


class UserCreate(RegisterRequest):
    """User creation."""
    pass


class UserInDB(UserBase):
    """User as stored in database."""
    id: int
    password_hash: str
    is_active: bool
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserResponse(UserInDB):
    """User response DTO."""
    class Config:
        from_attributes = True


# --- Mother Pregnancy Profile ---

class MotherPregnancyProfileBase(BaseModel):
    """Base pregnancy profile fields."""
    lmp_date: Optional[datetime] = Field(None, description="Last Menstrual Period date")
    edd_date: Optional[datetime] = Field(None, description="Estimated Due Date")
    conception_date: Optional[datetime] = Field(None, description="Conception date")
    current_gestational_weeks: Optional[conint(ge=0)] = Field(
        None, ge=0, description="Current gestational weeks"
    )
    trimester: Optional[str] = Field(None, description="Trimester name")
    pregnancy_type: str = Field("single", description="single, twin, multiple")
    notes: Optional[str] = Field(None, description="Additional notes")


class MotherPregnancyProfileCreate(MotherPregnancyProfileBase):
    """Pregnancy profile creation."""
    user_id: int


class MotherPregnancyProfileUpdate(BaseModel):
    """Pregnancy profile update."""
    lmp_date: Optional[datetime] = Field(None)
    edd_date: Optional[datetime] = Field(None)
    current_gestational_weeks: Optional[conint(ge=0)] = Field(None, ge=0)
    trimester: Optional[str] = Field(None)
    pregnancy_type: Optional[str] = Field(None, pattern="^(single|twin|multiple)$")
    notes: Optional[str] = Field(None)


class MotherPregnancyProfileResponse(MotherPregnancyProfileBase):
    """Pregnancy profile response."""
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# --- Baby Growth Week ---

class BabyGrowthWeekBase(BaseModel):
    """Base baby growth week fields."""
    week_number: conint(ge=1, le=40) = Field(..., ge=1, le=40, description="Gestational week")
    trimester: conint(ge=1, le=3) = Field(..., ge=1, le=3, description="Trimester number")
    illustration_identifier: str = Field(..., description="Asset identifier key")
    fruit_vegetable_comparison: Optional[str] = Field(None, description="e.g., 'Banana'")
    size_cm: Optional[confloat(ge=0)] = Field(None, ge=0, description="Size in cm")
    weight_g: Optional[conint(ge=0)] = Field(None, ge=0, description="Weight in grams")
    educational_summary: Optional[str] = Field(None, description="Short educational summary")
    source: Optional[str] = Field(None, description="Source: clinical, educational")
    review_date: Optional[datetime] = Field(None, description="Review date")
    clinical_review_status: str = Field(
        "pending", description="pending, approved, reviewed"
    )
    doctor_questions: Optional[str] = Field(None, description="Questions for doctor")


class BabyGrowthWeekCreate(BabyGrowthWeekBase):
    """Baby growth week creation."""
    pregnancy_profile_id: int


class BabyGrowthWeekUpdate(BaseModel):
    """Baby growth week update."""
    week_number: Optional[conint(ge=1, le=40)] = Field(None, ge=1, le=40)
    trimester: Optional[conint(ge=1, le=3)] = Field(None, ge=1, le=3)
    illustration_identifier: Optional[str] = Field(None)
    fruit_vegetable_comparison: Optional[str] = Field(None)
    size_cm: Optional[confloat(ge=0)] = Field(None, ge=0)
    weight_g: Optional[conint(ge=0)] = Field(None, ge=0)
    educational_summary: Optional[str] = Field(None)
    source: Optional[str] = Field(None)
    review_date: Optional[datetime] = Field(None)
    clinical_review_status: Optional[str] = Field(None, pattern="^(pending|approved|reviewed)$")
    doctor_questions: Optional[str] = Field(None)


class BabyGrowthWeekResponse(BabyGrowthWeekBase):
    """Baby growth week response."""
    id: int
    pregnancy_profile_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# --- Daily Check-In ---

class DailyCheckInBase(BaseModel):
    """Base daily check-in fields."""
    sleep_duration_hours: Optional[confloat(ge=0, le=24)] = Field(
        None, ge=0, le=24, description="Sleep hours"
    )
    sleep_quality: Optional[conint(ge=1, le=10)] = Field(
        None, ge=1, le=10, description="Sleep quality 1-10"
    )
    mood: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10, description="Mood 1-10")
    energy: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10, description="Energy 1-10")
    stress: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10, description="Stress 1-10")
    symptoms: Optional[str] = Field(None, description="Symptoms description")
    hydration_status: Optional[str] = Field(
        None, description="e.g., 'good', 'fair', 'poor'"
    )
    activity_minutes: Optional[conint(ge=0)] = Field(
        None, ge=0, description="Activity minutes"
    )
    notes: Optional[str] = Field(None, description="Additional notes")


class DailyCheckInCreate(DailyCheckInBase):
    """Daily check-in creation."""
    mother_profile_id: int


class DailyCheckInUpdate(BaseModel):
    """Daily check-in update."""
    sleep_duration_hours: Optional[confloat(ge=0, le=24)] = Field(None, ge=0, le=24)
    sleep_quality: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10)
    mood: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10)
    energy: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10)
    stress: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10)
    symptoms: Optional[str] = Field(None)
    hydration_status: Optional[str] = Field(None)
    activity_minutes: Optional[conint(ge=0)] = Field(None, ge=0)
    notes: Optional[str] = Field(None)


class DailyCheckInResponse(DailyCheckInBase):
    """Daily check-in response."""
    id: int
    mother_profile_id: int
    check_in_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Symptom Log ---

class SymptomLogBase(BaseModel):
    """Base symptom log fields."""
    symptom_name: str = Field(..., min_length=1, description="Symptom name")
    severity: Optional[conint(ge=1, le=10)] = Field(
        None, ge=1, le=10, description="Severity 1-10"
    )
    started_date: Optional[datetime] = Field(None, description="Started date")
    ended_date: Optional[datetime] = Field(None, description="Ended date")
    notes: Optional[str] = Field(None, description="Additional notes")


class SymptomLogCreate(SymptomLogBase):
    """Symptom log creation."""
    mother_profile_id: int


class SymptomLogUpdate(BaseModel):
    """Symptom log update."""
    symptom_name: Optional[str] = Field(None, min_length=1)
    severity: Optional[conint(ge=1, le=10)] = Field(None, ge=1, le=10)
    started_date: Optional[datetime] = Field(None)
    ended_date: Optional[datetime] = Field(None)
    notes: Optional[str] = Field(None)


class SymptomLogResponse(SymptomLogBase):
    """Symptom log response."""
    id: int
    mother_profile_id: int
    log_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Manual Measurement ---

class ManualMeasurementBase(BaseModel):
    """Base manual measurement fields."""
    measurement_type: str = Field(
        ..., description="e.g., blood_pressure, pulse, weight"
    )
    value: confloat(ge=0) = Field(..., ge=0, description="Measurement value")
    unit: str = Field(..., description="e.g., mmHg, bpm, kg")
    source: str = Field(
        default="user_entered",
        description="user_entered, clinician_entered, demo",
    )


class ManualMeasurementCreate(ManualMeasurementBase):
    """Manual measurement creation."""
    mother_profile_id: int


class ManualMeasurementUpdate(BaseModel):
    """Manual measurement update."""
    measurement_type: Optional[str] = Field(None)
    value: Optional[confloat(ge=0)] = Field(None, ge=0)
    unit: Optional[str] = Field(None)
    source: Optional[str] = Field(None)


class ManualMeasurementResponse(ManualMeasurementBase):
    """Manual measurement response."""
    id: int
    mother_profile_id: int
    measurement_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Appointment ---

class AppointmentBase(BaseModel):
    """Base appointment fields."""
    title: str = Field(..., min_length=1, description="Appointment title")
    description: Optional[str] = Field(None, description="Appointment description")
    appointment_date: datetime = Field(..., description="Appointment date/time")


class AppointmentCreate(AppointmentBase):
    """Appointment creation."""
    mother_profile_id: int


class AppointmentUpdate(BaseModel):
    """Appointment update."""
    title: Optional[str] = Field(None, min_length=1)
    description: Optional[str] = Field(None)
    appointment_date: Optional[datetime] = Field(None)


class AppointmentResponse(AppointmentBase):
    """Appointment response."""
    id: int
    mother_profile_id: int
    created_at: datetime
    updated_at: datetime
    is_demo: bool

    class Config:
        from_attributes = True


# --- Task ---

class TaskBase(BaseModel):
    """Base task fields."""
    title: str = Field(..., min_length=1, description="Task title")
    description: Optional[str] = Field(None, description="Task description")
    assigned_to: Optional[str] = Field(
        None, description="e.g., mother, partner, doctor, Rohan Sharma"
    )
    priority: str = Field(
        "medium", description="low, medium, high"
    )  # low, medium, high
    due_date: Optional[datetime] = Field(None, description="Due date")


class TaskCreate(TaskBase):
    """Task creation."""
    mother_profile_id: int


class TaskUpdate(BaseModel):
    """Task update."""
    title: Optional[str] = Field(None, min_length=1)
    description: Optional[str] = Field(None)
    assigned_to: Optional[str] = Field(None)
    status: Optional[str] = Field(
        None, description="pending, in_progress, completed, cancelled"
    )
    priority: Optional[str] = Field(
        None, description="low, medium, high"
    )
    due_date: Optional[datetime] = Field(None)


class TaskResponse(TaskBase):
    """Task response."""
    id: int
    mother_profile_id: int
    status: str
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    is_demo: bool

    class Config:
        from_attributes = True


# --- Expense ---

class ExpenseBase(BaseModel):
    """Base expense fields."""
    amount: confloat(ge=0) = Field(..., ge=0, description="Amount in INR")
    category: Optional[str] = Field(None, description="e.g., medical, pharmacy, essentials")
    payment_method: Optional[str] = Field(
        None, description="e.g., UPI, Cash, Card"
    )
    description: Optional[str] = Field(None, description="Expense description")


class ExpenseCreate(ExpenseBase):
    """Expense creation."""
    mother_profile_id: int


class ExpenseUpdate(BaseModel):
    """Expense update."""
    amount: Optional[confloat(ge=0)] = Field(None, ge=0)
    category: Optional[str] = Field(None)
    payment_method: Optional[str] = Field(None)
    description: Optional[str] = Field(None)


class ExpenseResponse(ExpenseBase):
    """Expense response."""
    id: int
    mother_profile_id: int
    recorded_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Family Invitation ---

class FamilyInvitationBase(BaseModel):
    """Base family invitation fields."""
    invitee_email: EmailStr = Field(..., description="Invitee email")
    invitee_name: Optional[str] = Field(None, description="Invitee name")
    role: str = Field(..., description="Role: mother, partner, doctor")


class FamilyInvitationCreate(FamilyInvitationBase):
    """Family invitation creation."""
    inviter_user_id: int


class FamilyInvitationResponse(FamilyInvitationBase):
    """Family invitation response."""
    id: int
    invitation_code: str
    status: str
    created_at: datetime
    accepted_at: Optional[datetime]
    expires_at: Optional[datetime]

    class Config:
        from_attributes = True


# --- Consent Grant ---

class ConsentGrantBase(BaseModel):
    """Base consent grant fields."""
    granted_to_role: str = Field(..., description="partner, doctor")
    granted_scope: Optional[Dict[str, Any]] = Field(
        None, description="JSON describing what was granted"
    )


class ConsentGrantCreate(ConsentGrantBase):
    """Consent grant creation."""
    mother_profile_id: int


class ConsentGrantUpdate(BaseModel):
    """Consent grant update."""
    granted_scope: Optional[Dict[str, Any]] = Field(None)


class ConsentGrantResponse(ConsentGrantBase):
    """Consent grant response."""
    id: int
    mother_profile_id: int
    granted_at: datetime
    revoked_at: Optional[datetime]
    is_demo: bool

    class Config:
        from_attributes = True


# --- Doctor Assignment ---

class DoctorAssignmentBase(BaseModel):
    """Base doctor assignment fields."""
    doctor_user_id: int = Field(..., description="Assigned doctor user ID")
    is_primary: bool = Field(True, description="Is primary doctor")


class DoctorAssignmentCreate(DoctorAssignmentBase):
    """Doctor assignment creation."""
    mother_profile_id: int


class DoctorAssignmentResponse(DoctorAssignmentBase):
    """Doctor assignment response."""
    id: int
    mother_profile_id: int
    assigned_at: datetime
    is_demo: bool

    class Config:
        from_attributes = True


# --- Medical Document ---

class MedicalDocumentBase(BaseModel):
    """Base medical document fields."""
    title: str = Field(..., min_length=1, description="Document title")
    document_type: str = Field(
        ..., description="e.g., ultrasound, blood_work, nt_scan"
    )


class MedicalDocumentCreate(MedicalDocumentBase):
    """Medical document creation."""
    mother_profile_id: int


class MedicalDocumentUpdate(BaseModel):
    """Medical document update."""
    title: Optional[str] = Field(None, min_length=1)
    document_type: Optional[str] = Field(None)


class MedicalDocumentResponse(MedicalDocumentBase):
    """Medical document response."""
    id: int
    mother_profile_id: int
    storage_path: str
    uploaded_by: Optional[str] = Field(None, description="mother, doctor")
    uploaded_at: datetime
    is_demo: bool

    class Config:
        from_attributes = True


# --- Clinician Note ---

class ClinicianNoteBase(BaseModel):
    """Base clinician note fields."""
    title: Optional[str] = Field(None, min_length=1, description="Note title")
    observations: Optional[str] = Field(None, description="Clinical observations")
    prescriptions: Optional[str] = Field(None, description="Prescriptions")


class ClinicianNoteCreate(ClinicianNoteBase):
    """Clinician note creation."""
    mother_profile_id: int
    doctor_user_id: int


class ClinicianNoteUpdate(BaseModel):
    """Clinician note update."""
    title: Optional[str] = Field(None, min_length=1)
    observations: Optional[str] = Field(None)
    prescriptions: Optional[str] = Field(None)


class ClinicianNoteResponse(ClinicianNoteBase):
    """Clinician note response."""
    id: int
    mother_profile_id: int
    doctor_user_id: int
    note_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Baby Profile ---

class BabyProfileBase(BaseModel):
    """Base baby profile fields."""
    birth_date: Optional[datetime] = Field(None, description="Birth date")
    birth_weight: Optional[confloat(ge=0)] = Field(
        None, ge=0, description="Birth weight in kg"
    )
    birth_length: Optional[confloat(ge=0)] = Field(
        None, ge=0, description="Birth length in cm"
    )
    gender: Optional[str] = Field(None, description="Baby gender")


class BabyProfileCreate(BabyProfileBase):
    """Baby profile creation."""
    mother_profile_id: int


class BabyProfileResponse(BabyProfileBase):
    """Baby profile response."""
    id: int
    mother_profile_id: int
    birth_weight: Optional[Decimal] = Field(None, description="Birth weight in kg")
    birth_length: Optional[Decimal] = Field(None, description="Birth length in cm")
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Baby Care Event ---

class BabyCareEventBase(BaseModel):
    """Base baby care event fields."""
    event_type: str = Field(
        ..., description="e.g., feeding, diaper_change, sleep"
    )
    details: Optional[str] = Field(None, description="Event details")


class BabyCareEventCreate(BabyCareEventBase):
    """Baby care event creation."""
    mother_profile_id: int


class BabyCareEventUpdate(BaseModel):
    """Baby care event update."""
    event_type: Optional[str] = Field(None, min_length=1)
    details: Optional[str] = Field(None)


class BabyCareEventResponse(BabyCareEventBase):
    """Baby care event response."""
    id: int
    mother_profile_id: int
    event_date: datetime
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True


# --- Notification ---

class NotificationBase(BaseModel):
    """Base notification fields."""
    title: str = Field(..., min_length=1, description="Notification title")
    message: str = Field(..., min_length=1, description="Notification message")
    type: Optional[str] = Field(
        None, description="e.g., appointment, medication, milestone"
    )


class NotificationCreate(NotificationBase):
    """Notification creation."""
    user_id: int


class NotificationResponse(NotificationBase):
    """Notification response."""
    id: int
    user_id: int
    is_read: bool
    created_at: datetime
    related_entity_type: Optional[str] = Field(None)
    related_entity_id: Optional[int] = Field(None)

    class Config:
        from_attributes = True


# --- Insight Summary ---

class InsightSummaryBase(BaseModel):
    """Base insight summary fields."""
    period_start: datetime = Field(..., description="Period start date")
    period_end: datetime = Field(..., description="Period end date")
    summary_text: Optional[str] = Field(None, description="AI-generated summary")


class InsightSummaryCreate(InsightSummaryBase):
    """Insight summary creation."""
    mother_profile_id: int


class InsightSummaryResponse(InsightSummaryBase):
    """Insight summary response."""
    id: int
    mother_profile_id: int
    generated_at: datetime
    is_demo: bool

    class Config:
        from_attributes = True


# --- Audit Event ---

class AuditEventBase(BaseModel):
    """Base audit event fields."""
    target_entity: str = Field(..., description="e.g., user, pregnancy_profile, consent")
    target_entity_id: Optional[int] = Field(None, description="Target entity ID")
    action: str = Field(..., description="Action performed")
    details: Optional[str] = Field(None, description="Additional details")


class AuditEventCreate(AuditEventBase):
    """Audit event creation."""
    performed_by_user_id: int


class AuditEventResponse(AuditEventBase):
    """Audit event response."""
    id: int
    target_user_id: Optional[int]
    performed_by_user_id: int
    ip_address: Optional[str] = Field(None)
    user_agent: Optional[str] = Field(None)
    created_at: datetime

    class Config:
        from_attributes = True


# --- API Response Wrappers ---

class ApiResponse(BaseModel):
    """Generic API success response."""
    success: bool = True
    data: Any
    message: Optional[str] = None


class ApiErrorResponse(BaseModel):
    """Generic API error response."""
    success: bool = False
    error: str
    message: str
    code: str


class PaginationParams(BaseModel):
    """Pagination parameters."""
    page: int = Field(default=1, ge=1, description="Page number")
    size: int = Field(default=20, ge=1, le=100, description="Page size")


class PaginatedResponse(BaseModel):
    """Paginated API response."""
    items: List[Any]
    total: int
    page: int
    size: int
    pages: int