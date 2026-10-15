"""Demo seed data for maternal health platform development."""

from datetime import datetime, timedelta
from decimal import Decimal

from sqlalchemy.orm import Session

from ...core.database import get_db, init_db
from ...models.models import (
    User, MotherPregnancyProfile, BabyGrowthWeek,
    DailyCheckIn, SymptomLog, ManualMeasurement,
    Appointment, Task, Expense,
    FamilyInvitation, ConsentGrant, DoctorAssignment,
    MedicalDocument, ClinicianNote, BabyProfile,
    BabyCareEvent, Notification, InsightSummary,
    AuditEvent
)
from ...core.security import get_password_hash


def seed_demo_data(db: Session):
    """Seed demo data for development."""
    
    # --- Demo Users ---
    
    # Mother user
    mother_email = "ananya@example.com"
    mother_exists = db.query(User).filter(User.email == mother_email).first()
    if not mother_exists:
        mother_user = User(
            email=mother_email,
            full_name="Ananya Sharma",
            password_hash=get_password_hash("password123"),
            role="mother",
            is_active=True,
            is_verified=True,
        )
        db.add(mother_user)
        db.flush()
    else:
        mother_user = mother_exists
    
    # Partner user
    partner_email = "rohan@example.com"
    partner_exists = db.query(User).filter(User.email == partner_email).first()
    if not partner_exists:
        partner_user = User(
            email=partner_email,
            full_name="Rohan Sharma",
            password_hash=get_password_hash("password123"),
            role="partner",
            is_active=True,
            is_verified=True,
        )
        db.add(partner_user)
        db.flush()
    else:
        partner_user = partner_exists
    
    # Doctor user
    doctor_email = "dr.sharma@example.com"
    doctor_exists = db.query(User).filter(User.email == doctor_email).first()
    if not doctor_exists:
        doctor_user = User(
            email=doctor_email,
            full_name="Dr. Sunita Sharma",
            password_hash=get_password_hash("password123"),
            role="doctor",
            is_active=True,
            is_verified=True,
        )
        db.add(doctor_user)
        db.flush()
    else:
        doctor_user = doctor_exists
    
    # --- Mother Pregnancy Profile ---
    
    profile_exists = db.query(MotherPregnancyProfile).filter(
        MotherPregnancyProfile.user_id == mother_user.id
    ).first()
    
    if not profile_exists:
        # LMP: April 15, 2026 → EDD: January 22, 2027 (approx 40 weeks later)
        from datetime import date
        lmp_date = datetime(2026, 4, 15)
        edd_date = datetime(2027, 1, 22)
        
        profile = MotherPregnancyProfile(
            user_id=mother_user.id,
            lmp_date=lmp_date,
            edd_date=edd_date,
            conception_date=datetime(2026, 5, 1),
            current_gestational_weeks=20,
            trimester=2,
            pregnancy_type="single",
            notes="Demo pregnancy profile - Ananya Sharma",
        )
        db.add(profile)
        db.flush()
    else:
        profile = profile_exists
    
    # --- Baby Growth Weeks (Week 1-40) ---
    
    # Seed a few sample weeks
    for week in [1, 4, 8, 12, 16, 20, 28, 32, 36, 40]:
        existing = db.query(BabyGrowthWeek).filter(
            BabyGrowthWeek.pregnancy_profile_id == profile.id,
            BabyGrowthWeek.week_number == week,
        ).first()
        
        if not existing:
            # Simple fruit/vegetable comparisons for key weeks
 fruit_comparisons = {
                1: "Poppy seed",
                4: "Avocado seed", 
                8: "Kidney bean",
                12: "Lime",
                16: "Avocado",
                20: "Banana",
                28: "Eggplant",
                32: "Rutabaga",
                36: "Romaine lettuce",
                40: "Watermelon",
            }
            
            size_cms = {
                1: 0.1,
                4: 0.1,
                8: 1.6,
                12: 5.4,
                16: 11.6,
                20: 25.6,
                28: 35.5,
                32: 42.5,
                36: 45.7,
                40: 51.2,
            }
            
            weight_g = {
                1: 0.0,
                4: 0.0,
                8: 1,
                12: 14,
                16: 100,
                20: 300,
                28: 1005,
                32: 1700,
                36: 2570,
                40: 3200,
            }
            
            trimester = 1 if week <= 13 else (2 if week <= 27 else 3)
            
            week_data = BabyGrowthWeek(
                pregnancy_profile_id=profile.id,
                week_number=week,
                trimester=trimester,
                illustration_identifier=f"week_{week}",
                fruit_vegetable_comparison=fruit_comparisons.get(week),
                size_cm=size_cms.get(week),
                weight_g=weight_g.get(week),
                educational_summary=f"Baby is about the size of a {fruit_comparisons.get(week, 'fruit')} this week",
                source="clinical",
                clinical_review_status="approved",
                doctor_questions=f"Questions about week {week} development",
            )
            db.add(week_data)
    
    db.flush()
    
    # --- Daily Check-Ins (sample) ---
    
    for i in range(5):
        check_in_date = datetime.now() - timedelta(days=i*7)
        is_demo = True
        
        check_in = DailyCheckIn(
            mother_profile_id=profile.id,
            check_in_date=check_in_date,
            sleep_duration_hours=7.0 + (i * 0.5),
            sleep_quality=7 - i,
            mood=8 - i,
            energy=7 - i,
            stress=5 + i,
            hydration_status="good" if i % 2 == 0 else "fair",
            activity_minutes=30 + (i * 10),
            notes=f"Demo check-in {i+1}",
            is_demo=is_demo,
        )
        db.add(check_in)
    
    db.flush()
    
    # --- Symptom Logs ---
    
    symptoms = ["Morning Sickness", "Lower Back Pain", "Headache", "Swelling", "Heartburn"]
    for i in range(3):
        symptom_date = datetime.now() - timedelta(days=i*10)
        
        symptom = SymptomLog(
            mother_profile_id=profile.id,
            log_date=symptom_date,
            symptom_name=symptoms[i],
            severity=5 + (i % 3),
            notes=f"Demo symptom log {i+1}",
            is_demo=True,
        )
        db.add(symptom)
    
    db.flush()
    
    # --- Manual Measurements ---
    
    measurements = [
        {"type": "blood_pressure", "value": "110/70", "unit": "mmHg", "source": "user_entered"},
        {"type": "weight", "value": "65.5", "unit": "kg", "source": "user_entered"},
        {"type": "pulse", "value": "78", "unit": "bpm", "source": "user_entered", "is_demo": True},
    ]
    
    for i, meas in enumerate(measurements):
        measurement = ManualMeasurement(
            mother_profile_id=profile.id,
            measurement_type=meas["type"],
            value=Decimal(meas["value"]) if meas["type"] != "pulse" else float(meas["value"]),
            unit=meas["unit"],
            source=meas.get("source", "user_entered"),
            is_demo=meas.get("is_demo", False),
            notes=f"Demo measurement {i+1}",
        )
        db.add(measurement)
    
    db.flush()
    
    # --- Appointments ---
    
    appointments = [
        {
            "title": "20-Week Anatomy Scan",
            "description": "Routine anatomy scan to check baby's development",
            "appointment_date": datetime(2026, 10, 24, 14, 30),
        },
        {
            "title": "Monthly Prenatal Checkup",
            "description": "Standard monthly prenatal visit",
            "appointment_date": datetime(2026, 11, 15, 10, 0),
        },
    ]
    
    for i, appt in enumerate(appointments):
        appointment = Appointment(
            mother_profile_id=profile.id,
            title=appt["title"],
            description=appt["description"],
            appointment_date=appt["appointment_date"],
            is_demo=True,
        )
        db.add(appointment)
    
    db.flush()
    
    # --- Tasks ---
    
    tasks = [
        {
            "title": "Take Folic Acid Daily",
            "description": "Take 5mg Folic Acid supplement every morning",
            "assigned_to": "mother",
            "priority": "high",
        },
        {
            "title": "Hospital Bag Preparation",
            "description": "Pack hospital bag for delivery",
            "assigned_to": "mother",
            "priority": "medium",
        },
        {
            "title": "Iron Supplements",
            "description": "Pick up Iron supplements from pharmacy",
            "assigned_to": "partner",
            "priority": "high",
        },
    ]
    
    for i, task_data in enumerate(tasks):
        task = Task(
            mother_profile_id=profile.id,
            title=task_data["title"],
            description=task_data["description"],
            assigned_to=task_data["assigned_to"],
            priority=task_data["priority"],
            is_demo=True,
        )
        db.add(task)
    
    db.flush()
    
    # --- Expenses ---
    
    expenses = [
        {
            "amount": Decimal("2500.00"),
            "category": "medical",
            "payment_method": "UPI",
            "description": "Monthly prenatal vitamins and supplements",
        },
        {
            "amount": Decimal("1500.00"),
            "category": "pharmacy",
            "payment_method": "Cash",
            "description": "Iron and calcium supplements",
        },
        {
            "amount": Decimal("3500.00"),
            "category": "essentials",
            "payment_method": "UPI",
            "description": "Maternity clothing and supplies",
        },
    ]
    
    for i, exp_data in enumerate(expenses):
        expense = Expense(
            mother_profile_id=profile.id,
            amount=exp_data["amount"],
            category=exp_data["category"],
            payment_method=exp_data["payment_method"],
            description=exp_data["description"],
            is_demo=True,
        )
        db.add(expense)
    
    db.flush()
    
    # --- Family Invitation ---
    
    invitation_exists = db.query(FamilyInvitation).filter(
        FamilyInvitation.invitee_email == partner_email,
    ).first()
    
    if not invitation_exists:
        invitation = FamilyInvitation(
            inviter_user_id=mother_user.id,
            invitee_email=partner_email,
            invitee_name="Rohan Sharma",
            role="partner",
            invitation_code="MATRU-DEMO-001",
            status="pending",
            expires_at=datetime.now() + timedelta(days=30),
        )
        db.add(invitation)
    
    db.flush()
    
    # --- Consent Grant ---
    
    consent_exists = db.query(ConsentGrant).filter(
        ConsentGrant.mother_profile_id == profile.id,
    ).first()
    
    if not consent_exists:
        consent = ConsentGrant(
            mother_profile_id=profile.id,
            granted_to_role="partner",
            granted_scope={
                "symptom_logs": True,
                "appointment_dates": True,
                "expense_details": True,
                "baby_care_events": True,
            },
        )
        db.add(consent)
    
    db.flush()
    
    # --- Doctor Assignment ---
    
    assignment_exists = db.query(DoctorAssignment).filter(
        DoctorAssignment.mother_profile_id == profile.id,
    ).first()
    
    if not assignment_exists:
        assignment = DoctorAssignment(
            mother_profile_id=profile.id,
            doctor_user_id=doctor_user.id,
            is_primary=True,
        )
        db.add(assignment)
    
    db.flush()
    
    # --- Medical Documents ---
    
    doc_exists = db.query(MedicalDocument).filter(
        MedicalDocument.mother_profile_id == profile.id,
    ).first()
    
    if not doc_exists:
        document = MedicalDocument(
            mother_profile_id=profile.id,
            title="12-Week NT Ultrasound Scan",
            document_type="ultrasound",
            storage_path="documents/mother/nt_scan.pdf",
            uploaded_by="mother",
        )
        db.add(document)
    
    db.flush()
    
    # --- Clinician Notes ---
    
    note_exists = db.query(ClinicianNote).filter(
        ClinicianNote.mother_profile_id == profile.id,
    ).first()
    
    if not note_exists:
        note = ClinicianNote(
            mother_profile_id=profile.id,
            doctor_user_id=doctor_user.id,
            title="First Prenatal Visit",
            observations="Fetal heart rate normal (142 bpm). Mother in good health. "
                       "Continue Folic Acid + Iron supplements.",
            prescriptions="Folic Acid 5mg (daily) + Iron 60mg (daily)",
        )
        db.add(note)
    
    db.flush()
    
    # --- Baby Profile ---
    
    baby_profile_exists = db.query(BabyProfile).filter(
        BabyProfile.mother_profile_id == profile.id,
    ).first()
    
    if not baby_profile_exists:
        baby_profile = BabyProfile(
            mother_profile_id=profile.id,
            birth_date=datetime(2026, 10, 15),
            birth_weight=Decimal("3.2"),
            birth_length=Decimal("50"),
            gender="Female",
        )
        db.add(baby_profile)
    
    db.flush()
    
    # --- Baby Care Events ---
    
    care_events = [
        {
            "event_type": "feeding",
            "details": "Breastfeeding - 20 minutes at 8:00 AM",
        },
        {
            "event_type": "diaper_change",
            "details": "Wet diaper at 9:30 AM",
        },
    ]
    
    for i, event_data in enumerate(care_events):
        event = BabyCareEvent(
            mother_profile_id=profile.id,
            event_type=event_data["event_type"],
            details=event_data["details"],
            is_demo=True,
        )
        db.add(event)
    
    db.flush()
    
    # --- Notifications ---
    
    notifications = [
        {
            "user_id": mother_user.id,
            "title": "Upcoming Appointment",
            "message": "Your 20-Week Anatomy Scan is scheduled for October 24, 2026",
            "type": "appointment",
        },
        {
            "user_id": partner_user.id,
            "title": "New Task Assigned",
            "message": "You've been assigned to pick up Iron supplements",
            "type": "task",
        },
    ]
    
    for i, notif_data in enumerate(notifications):
        notification = Notification(
            user_id=notif_data["user_id"],
            title=notif_data["title"],
            message=notif_data["message"],
            type=notif_data["type"],
        )
        db.add(notification)
    
    db.flush()
    
    # --- Insight Summaries ---
    
    insight_exists = db.query(InsightSummary).filter(
        InsightSummary.mother_profile_id == profile.id,
    ).first()
    
    if not insight_exists:
        insight = InsightSummary(
            mother_profile_id=profile.id,
            period_start=datetime(2026, 10, 1),
            period_end=datetime(2026, 10, 31),
            summary_text="Demo: Sleep average 7.8 hours/night. Hydration target met on 5 of 7 days. "
                        "Fetal development tracking week 20: Baby is about the size of a banana "
                        "(25.6 cm, 300g). All vital signs within normal range.",
            is_demo=True,
        )
        db.add(insight)
    
    # --- Audit Events ---
    
    # Create some audit events for key actions
    audit_events = [
        {
            "target_entity": "user",
            "target_entity_id": mother_user.id,
            "action": "user_registered",
            "performed_by_user_id": None,
            "details": "Mother user registered via demo seed",
        },
        {
            "target_entity": "user",
            "target_entity_id": partner_user.id,
            "action": "family_invite_sent",
            "performed_by_user_id": mother_user.id,
            "details": "Partner invitation sent to rohan@example.com",
        },
        {
            "target_entity": "consent",
            "target_entity_id": 1,
            "action": "consent_granted",
            "performed_by_user_id": mother_user.id,
            "details": "Partner consent granted for symptom log sharing",
        },
    ]
    
    for i, audit_data in enumerate(audit_events):
        audit = AuditEvent(
            target_entity=audit_data["target_entity"],
            target_entity_id=audit_data["target_entity_id"],
            action=audit_data["action"],
            performed_by_user_id=audit_data.get("performed_by_user_id"),
            details=audit_data["details"],
        )
        db.add(audit)
    
    db.commit()
    print("✅ Demo seed data committed successfully!")


def clear_demo_data(db: Session):
    """Clear all demo data (keep real user data if any)."""
    # Delete in reverse dependency order
    models_to_clear = [
        AuditEvent, InsightSummary, Notification, BabyCareEvent,
        BabyProfile, MedicalDocument, ClinicianNote, ConsentGrant,
        DoctorAssignment, FamilyInvitation, Expense, Task,
        Appointment, ManualMeasurement, SymptomLog, DailyCheckIn,
        BabyGrowthWeek, MotherPregnancyProfile, User,
    ]
    
    for model in models_to_clear:
        db.query(model).delete()
    
    db.commit()
    print("♻️ Demo data cleared successfully!")