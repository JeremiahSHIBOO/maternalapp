"""AI provider interface for future LLM integration."""

from typing import Optional, Dict, Any, List
from datetime import datetime


class AIProviderInterface:
    """Abstract interface for AI providers."""
    
    def summarize_checkins(
        self,
        checkin_records: List[Dict[str, Any]],
        period_days: int,
    ) -> str:
        """Summarize authorized check-in records."""
        raise NotImplementedError
    
    def explain_educational_content(
        self,
        content_id: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Explain reviewed educational content."""
        raise NotImplementedError
    
    def prepare_clinician_questions(
        self,
        patient_summary: str,
        consultation_history: Optional[str] = None,
    ) -> List[str]:
        """Prepare questions for a clinician."""
        raise NotImplementedError
    
    def summarize_appointments_and_tasks(
        self,
        appointments: List[Dict[str, Any]],
        tasks: List[Dict[str, Any]],
    ) -> str:
        """Summarize appointments and family tasks."""
        raise NotImplementedError


class MockAIProvider(AIProviderInterface):
    """Mock AI provider returning deterministic sample responses.
    
    Does not call a real LLM. All responses are pre-built for development.
    """
    
    def summarize_checkins(
        self,
        checkin_records: List[Dict[str, Any]],
        period_days: int,
    ) -> str:
        """Return a deterministic summary of check-in records."""
        if not checkin_records:
            return f"No check-in records found for the last {period_days} days."
        
        avg_sleep = sum(
            r.get("sleep_duration_hours", 0) or 0
            for r in checkin_records
        ) / len(checkin_records)
        
        hydration_met = sum(
            1 for r in checkin_records
            if r.get("hydration_status") == "good"
        )
        
        return (
            f"Analysis of {len(checkin_records)} check-ins over {period_days} days:\n"
            f"- Average sleep duration: {avg_sleep:.1f} hours/night\n"
            f"- Hydration target met on {hydration_met}/{len(checkin_records)} days\n"
            f"- Overall trend: {'Healthy patterns observed' if avg_sleep >= 7 else 'Consider reviewing sleep habits'}"
        )
    
    def explain_educational_content(
        self,
        content_id: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Return deterministic explanation of educational content."""
        return (
            f"Educational content ID: {content_id}\n"
            f"This week's focus: Baby's developmental milestones and "
            f"comfort measures for {user_context.get('trimester', 'current stage') if user_context else ''}."
        )
    
    def prepare_clinician_questions(
        self,
        patient_summary: str,
        consultation_history: Optional[str] = None,
    ) -> List[str]:
        """Return deterministic clinician questions."""
        base_questions = [
            "How is the baby's growth progressing this week?",
            "Are there any new or worsening symptoms?",
            "Is the recommended supplement schedule being followed?",
            "Any concerns about hydration or nutrition?",
        ]
        
        if consultation_history:
            base_questions.append(
                "How do current symptoms compare to previous consultations?"
            )
        
        return base_questions
    
    def summarize_appointments_and_tasks(
        self,
        appointments: List[Dict[str, Any]],
        tasks: List[Dict[str, Any]],
    ) -> str:
        """Return deterministic summary of appointments and tasks."""
        num_appointments = len(appointments)
        num_tasks = len(tasks)
        completed_tasks = sum(
            1 for t in tasks if t.get("status") == "completed"
        )
        
        return (
            f"Summary: {num_appointments} appointments scheduled, "
            f"{num_tasks} tasks total ({completed_tasks} completed).\n"
            f"Upcoming: {', '.join(a.get('title', 'Unknown') for a in appointments[:3])}"
        )