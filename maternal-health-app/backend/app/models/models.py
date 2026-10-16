"""SQLAlchemy models for maternal health platform."""

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    DECIMAL,
)
from sqlalchemy.orm import relationship

from .base import Base


class User(Base):
    """User account - shared across all roles."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False, default="mother")  # mother, partner, doctor
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    # Owned by mother
    mother_profile = relationship("MotherPregnancyProfile", back_populates="user", uselist=False)
    # Shared with partner
    shared_entries = relationship("SharedEntry", back_populates="shared_with_user", foreign_keys="SharedEntry.shared_with_user_id")
    # Partner invited by
    invited_by = relationship("FamilyInvitation", back_populates="invitee")
    # Invitations sent
    invitations_sent = relationship("FamilyInvitation", back_populates="inviter")
    # Doctor assignments (a doctor user's assigned patients)
    assigned_patients = relationship("DoctorAssignment", back_populates="doctor")
    # Audit events (AuditEvent.target_user_id points to this user)
    audit_events = relationship(
        "AuditEvent", back_populates="target_user",
        foreign_keys="[AuditEvent.target_user_id]",
    )
    # Clinician notes written by this user (doctor)
    clinician_notes_written = relationship("ClinicianNote", back_populates="doctor")
    # Notifications for this user
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")


class MotherPregnancyProfile(Base):
    """Mother's pregnancy profile and dating."""
    __tablename__ = "mother_pregnancy_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    lmp_date = Column(DateTime, nullable=True)  # Last Menstrual Period
    edd_date = Column(DateTime, nullable=True)  # Estimated Due Date
    conception_date = Column(DateTime, nullable=True)
    current_gestational_weeks = Column(Integer, nullable=True, default=0)
    trimester = Column(String(50), nullable=True)
    pregnancy_type = Column(String(50), nullable=True, default="single")  # single, twin, multiple
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    user = relationship("User", back_populates="mother_profile")
    baby_growth_records = relationship("BabyGrowthWeek", back_populates="pregnancy_profile", cascade="all, delete-orphan")
    check_ins = relationship("DailyCheckIn", back_populates="mother_profile", cascade="all, delete-orphan")
    symptoms = relationship("SymptomLog", back_populates="mother_profile", cascade="all, delete-orphan")
    measurements = relationship("ManualMeasurement", back_populates="mother_profile", cascade="all, delete-orphan")
    appointments = relationship("Appointment", back_populates="mother_profile", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="mother_profile", cascade="all, delete-orphan")
    expenses = relationship("Expense", back_populates="mother_profile", cascade="all, delete-orphan")
    baby_care_events = relationship("BabyCareEvent", back_populates="mother_profile", cascade="all, delete-orphan")
    consent_grants = relationship("ConsentGrant", back_populates="mother_profile", cascade="all, delete-orphan")
    insight_summaries = relationship("InsightSummary", back_populates="mother_profile", cascade="all, delete-orphan")
    baby_profile = relationship("BabyProfile", back_populates="mother_profile", uselist=False)
    assigned_doctor = relationship("DoctorAssignment", back_populates="mother")
    medical_documents = relationship("MedicalDocument", back_populates="mother_profile", cascade="all, delete-orphan")
    clinician_notes = relationship("ClinicianNote", back_populates="mother_profile", cascade="all, delete-orphan")


class BabyGrowthWeek(Base):
    """Weekly baby growth content."""
    __tablename__ = "baby_growth_weeks"

    id = Column(Integer, primary_key=True, index=True)
    pregnancy_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    week_number = Column(Integer, nullable=False)
    trimester = Column(Integer, nullable=False)
    illustration_identifier = Column(String(100), nullable=False)  # asset key/name
    fruit_vegetable_comparison = Column(String(100), nullable=True)  # e.g., "Banana"
    size_cm = Column(Float, nullable=True)  # approximate length in cm
    weight_g = Column(Integer, nullable=True)  # approximate weight in grams
    educational_summary = Column(Text, nullable=True)
    source = Column(String(100), nullable=True)  # e.g., "clinical", "educational"
    review_date = Column(DateTime, nullable=True)
    clinical_review_status = Column(String(50), nullable=True, default="pending")  # pending, approved, reviewed
    doctor_questions = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    pregnancy_profile = relationship("MotherPregnancyProfile", back_populates="baby_growth_records")


class DailyCheckIn(Base):
    """Daily health check-in."""
    __tablename__ = "daily_check_ins"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    check_in_date = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    sleep_duration_hours = Column(Float, nullable=True)
    sleep_quality = Column(Integer, nullable=True, comment="1-10 scale")
    mood = Column(Integer, nullable=True, comment="1-10 scale")
    energy = Column(Integer, nullable=True, comment="1-10 scale")
    stress = Column(Integer, nullable=True, comment="1-10 scale")
    symptoms = Column(Text, nullable=True)  # JSON or comma-separated
    hydration_status = Column(String(50), nullable=True, comment='e.g., good, fair, poor')
    activity_minutes = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)

    # Optional health readings (mirrors the Flutter check-in form and Supabase schema)
    bp_systolic_mmhg = Column(Integer, nullable=True)
    bp_diastolic_mmhg = Column(Integer, nullable=True)
    heart_rate_bpm = Column(Integer, nullable=True)
    hrv_ms = Column(Float, nullable=True)
    spo2_percent = Column(Float, nullable=True)
    respiratory_rate_per_min = Column(Integer, nullable=True)
    skin_temperature_c = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    steps_count = Column(Integer, nullable=True)
    measurement_source = Column(String(50), nullable=True, default="manual")

    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="check_ins")


class SharedEntry(Base):
    """Shared care entry between users (supports User.shared_entries)."""
    __tablename__ = "shared_entries"

    id = Column(Integer, primary_key=True, index=True)
    shared_with_user_id = Column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    entry_type = Column(String(50), nullable=True)
    entry_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    shared_with_user = relationship("User", back_populates="shared_entries")


class SymptomLog(Base):
    """Symptom tracking log."""
    __tablename__ = "symptom_logs"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    log_date = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    symptom_name = Column(String(255), nullable=False)
    severity = Column(Integer, nullable=True, comment="1-10 scale")
    started_date = Column(DateTime, nullable=True)
    ended_date = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="symptoms")


class ManualMeasurement(Base):
    """Optional manual health measurements."""
    __tablename__ = "manual_measurements"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    measurement_date = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    measurement_type = Column(
        String(50), nullable=False
    )  # e.g., "blood_pressure", "pulse", "weight"
    value = Column(DECIMAL(10, 2), nullable=True)  # safe decimal storage
    unit = Column(String(50), nullable=False)  # e.g., "mmHg", "bpm", "kg"
    source = Column(
        String(50), nullable=False, default="user_entered"
    )  # user_entered, clinician_entered, demo
    is_demo = Column(Boolean, default=False, comment="Demo data — not a real measurement")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="measurements")


class Appointment(Base):
    """Appointment scheduling."""
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    appointment_date = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )
    is_demo = Column(Boolean, default=False)

    mother_profile = relationship("MotherPregnancyProfile", back_populates="appointments")


class Task(Base):
    """Task list and assignment manager."""
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    assigned_to = Column(String(100), nullable=True, comment="e.g., 'mother', 'partner', 'doctor', 'Rohan Sharma'")
    status = Column(String(50), nullable=True, default="pending")  # pending, in_progress, completed, cancelled
    priority = Column(String(50), nullable=True, default="medium")  # low, medium, high
    due_date = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    mother_profile = relationship("MotherPregnancyProfile", back_populates="tasks")


class Expense(Base):
    """Family expenses overview (₹ INR)."""
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    amount = Column(DECIMAL(12, 2), nullable=False)  # safe decimal, INR
    category = Column(String(100), nullable=True)  # e.g., "medical", "pharmacy", "essentials"
    payment_method = Column(String(50), nullable=True)  # e.g., "UPI", "Cash", "Card"
    description = Column(Text, nullable=True)
    receipt_path = Column(String(500), nullable=True)
    recorded_date = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="expenses")


class FamilyInvitation(Base):
    """Family invitation system."""
    __tablename__ = "family_invitations"

    id = Column(Integer, primary_key=True, index=True)
    inviter_user_id = Column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    invitee_email = Column(String(255), nullable=False)
    invitee_name = Column(String(255), nullable=True)
    role = Column(String(50), nullable=True, comment="mother, partner, doctor")
    invitation_code = Column(String(100), unique=True, nullable=False)
    status = Column(String(50), nullable=True, default="pending")  # pending, accepted, expired
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    accepted_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)

    inviter = relationship("User", back_populates="invitations_sent")
    invitee = relationship("User", back_populates="invited_by")


class ConsentGrant(Base):
    """Consent/permission grants."""
    __tablename__ = "consent_grants"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    granted_to_role = Column(String(50), nullable=False, comment="partner, doctor")
    granted_scope = Column(Text, nullable=True)  # JSON describing what was granted
    granted_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    revoked_at = Column(DateTime, nullable=True)
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="consent_grants")


class DoctorAssignment(Base):
    """Doctor-patient assignment."""
    __tablename__ = "doctor_assignments"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    doctor_user_id = Column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    assigned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_primary = Column(Boolean, default=True)
    is_demo = Column(Boolean, default=False)

    mother = relationship("MotherPregnancyProfile", back_populates="assigned_doctor")
    doctor = relationship("User", back_populates="assigned_patients")


class MedicalDocument(Base):
    """Medical document metadata."""
    __tablename__ = "medical_documents"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    title = Column(String(255), nullable=False)
    document_type = Column(String(100), nullable=False)  # e.g., "ultrasound", "blood_work", "nt_scan"
    storage_path = Column(String(500), nullable=False)
    uploaded_by = Column(String(50), nullable=True, comment="mother, doctor")
    uploaded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="medical_documents")


class ClinicianNote(Base):
    """Clinician consultation notes."""
    __tablename__ = "clinician_notes"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    doctor_user_id = Column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    note_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    title = Column(String(255), nullable=True)
    observations = Column(Text, nullable=True)
    prescriptions = Column(Text, nullable=True)
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="clinician_notes")
    doctor = relationship("User", back_populates="clinician_notes_written")


class BabyProfile(Base):
    """Baby profile."""
    __tablename__ = "baby_profiles"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    birth_date = Column(DateTime, nullable=True)
    birth_weight = Column(DECIMAL(10, 2), nullable=True)  # birth weight in kg
    birth_length = Column(DECIMAL(10, 2), nullable=True)  # birth length in cm
    gender = Column(String(50), nullable=True)
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="baby_profile")


class BabyCareEvent(Base):
    """Baby care event logging."""
    __tablename__ = "baby_care_events"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    event_type = Column(String(100), nullable=False)  # e.g., "feeding", "diaper_change", "sleep"
    event_date = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    details = Column(Text, nullable=True)  # e.g., "Breastfeeding 20min", "Diaper wet"
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mother_profile = relationship("MotherPregnancyProfile", back_populates="baby_care_events")


class Notification(Base):
    """System notifications."""
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    type = Column(String(50), nullable=True, comment='e.g., appointment, medication, milestone')
    is_read = Column(Boolean, default=False)
    related_entity_type = Column(String(50), nullable=True)  # e.g., "appointment", "task"
    related_entity_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="notifications")


class InsightSummary(Base):
    """AI insight summaries."""
    __tablename__ = "insight_summaries"

    id = Column(Integer, primary_key=True, index=True)
    mother_profile_id = Column(
        Integer, ForeignKey("mother_pregnancy_profiles.id"), nullable=False
    )
    period_start = Column(DateTime, nullable=False)
    period_end = Column(DateTime, nullable=False)
    summary_text = Column(Text, nullable=True)
    generated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_demo = Column(Boolean, default=False)

    mother_profile = relationship("MotherPregnancyProfile", back_populates="insight_summaries")


class AuditEvent(Base):
    """Audit log for sensitive access and permission changes."""
    __tablename__ = "audit_events"

    id = Column(Integer, primary_key=True, index=True)
    target_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    target_entity = Column(String(100), nullable=True)  # e.g., "user", "pregnancy_profile", "consent"
    target_entity_id = Column(Integer, nullable=True)
    action = Column(String(255), nullable=False)
    performed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    ip_address = Column(String(45), nullable=True)  # IPv6 compatible
    user_agent = Column(Text, nullable=True)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    target_user = relationship("User", foreign_keys=[target_user_id])
    performer = relationship("User", foreign_keys=[performed_by_user_id])