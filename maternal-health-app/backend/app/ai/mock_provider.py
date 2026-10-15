"""Mock AI provider for development - no real LLM calls."""

from ...ai.interface import AIProviderInterface


class MockProvider(AIProviderInterface):
    """Concrete mock provider implementing the AI interface."""
    
    def summarize_checkins(
        self,
        checkin_records: list,
        period_days: int,
    ) -> str:
        return self._generate_checkin_summary(checkin_records, period_days)
    
    def explain_educational_content(
        self,
        content_id: str,
        user_context: dict = None,
    ) -> str:
        return self._generate_educational_explanation(content_id, user_context)
    
    def prepare_clinician_questions(
        self,
        patient_summary: str,
        consultation_history: str = None,
    ) -> list:
        return self._generate_clinician_questions(patient_summary, consultation_history)
    
    def summarize_appointments_and_tasks(
        self,
        appointments: list,
        tasks: list,
    ) -> str:
        return self._generate_appointment_task_summary(appointments, tasks)
    
    def _generate_checkin_summary(self, records, days):
        if not records:
            return f"No check-in records for the last {days} days."
        
        avg_sleep = sum(r.get("sleep_duration_hours", 0) or 0 for r in records) / len(records)
        hydration = sum(1 for r in records if r.get("hydration_status") == "good")
        
        return (
            f"Analysis of {len(records)} check-ins over {days} days:\n"
            f"- Average sleep: {avg_sleep:.1f} hours/night\n"
            f"- Hydration met: {hydration}/{len(records)} days\n"
            f"- Trend: {'Good patterns' if avg_sleep >= 7 else 'Review needed'}"
        )
    
    def _generate_educational_explanation(self, content_id, context=None):
        trimester = context.get("trimester", "") if context else ""
        return (
            f"Content ID: {content_id}\n"
            f"Focus: Baby's development during {trimester} trimester.\n"
            f"Key milestones: Organ formation, growth spurt, positional changes."
        )
    
    def _generate_clinician_questions(self, summary, history=None):
        questions = [
            "How is the baby growing this week?",
            "Any new symptoms or concerns?",
            "Are supplements being taken as prescribed?",
            "Hydration and nutrition status?",
        ]
        if history:
            questions.append("How do symptoms compare to previous visits?")
        return questions
    
    def _generate_appointment_task_summary(self, appointments, tasks):
        completed = sum(1 for t in tasks if t.get("status") == "completed")
        return (
            f"{len(appointments)} appointments, {len(tasks)} tasks "
            f"({completed} completed). Upcoming: {appointments[0]['title'] if appointments else 'None'}"
        )