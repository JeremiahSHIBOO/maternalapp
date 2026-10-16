"""Rules-based wellness insights engine.

Transparent and explainable. Produces observations and suggestions only;
never a medical diagnosis or causal claim. Thresholds are documented in
core.thresholds and configurable via environment variables.

Suggestion bank: 50 suggestions across the same categories (sleep, stress,
energy, mood, hydration, positive). On each check-in, 3-4 are randomly
selected from the suggestions that apply to the detected insights.
"""
from __future__ import annotations
import random
from typing import Any, Dict, List, Optional, Set, Tuple

from .core.thresholds import (
    SLEEP_SHORT_HOURS,
    SLEEP_RESTFUL_HOURS,
    SLEEP_QUALITY_POOR_THRESHOLD,
    STRESS_HIGH_THRESHOLD,
    ENERGY_LOW_THRESHOLD,
    ENERGY_HIGH_THRESHOLD,
    MOOD_LOW_THRESHOLD,
    MOOD_GOOD_THRESHOLD,
    HYDRATION_POOR_VALUES,
    SCORE_MAP,
    BASELINE_WINDOW_DAYS,
)
from .schemas.wellness import InsightItem


def _to_numeric(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return SCORE_MAP.get(str(value).strip().lower())


def _label(value: Any) -> Optional[str]:
    if value is None:
        return None
    return str(value)


# ---------------------------------------------------------------------------
# Suggestion bank: 100 suggestions across the same categories
# ---------------------------------------------------------------------------

SUGGESTIONS: Dict[str, List[str]] = {
    # --- Sleep (20) ---
    "sleep": [
        "Try a consistent bedtime and wake-up time, even on weekends.",
        "Dim lights and put away screens 30 minutes before bed.",
        "Keep your bedroom cool, dark, and quiet for better sleep.",
        "Avoid caffeine after 2 PM if you're having trouble sleeping.",
        "Try a warm shower or bath before bed to help you wind down.",
        "If you can't fall asleep after 20 minutes, get up and do something calm.",
        "Use your bed only for sleep and rest, not for work or phone scrolling.",
        "Try gentle stretching or breathing exercises before getting into bed.",
        "Avoid heavy meals close to bedtime.",
        "Get some natural sunlight in the morning to set your body clock.",
        "If you nap, keep it under 20 minutes and before 3 PM.",
        "Write down tomorrow's to-do list before bed to clear your mind.",
        "Try reading a physical book instead of scrolling on your phone.",
        "Keep a notepad by your bed to jot down thoughts that keep you awake.",
        "Use blackout curtains or an eye mask to block light.",
        "Try white noise or a fan to mask disruptive sounds.",
        "Avoid alcohol close to bedtime — it disrupts sleep quality.",
        "Do a 5-minute body scan meditation before lying down.",
        "Keep your bedroom temperature around 65-68°F (18-20°C).",
        "Make your bed in the morning — a tidy space helps sleep at night.",
    ],
    # --- Stress (20) ---
    "stress": [
        "Try box breathing: inhale 4 seconds, hold 4, exhale 4, hold 4.",
        "Take a 10-minute walk outside to clear your head.",
        "Write down what's stressing you, then note one small step for each.",
        "Schedule a short break every 90 minutes during your day.",
        "Listen to calming music or a nature soundscape.",
        "Practice progressive muscle relaxation from toes to head.",
        "Say no to one non-essential task today to protect your energy.",
        "Talk to someone you trust about what's on your mind.",
        "Spend 5 minutes on a hobby you enjoy to reset your mood.",
        "Reduce news and social media if they're adding to your stress.",
        "Try the 5-4-3-2-1 grounding technique: name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.",
        "Set a timer for 15 minutes of focused work, then a 2-minute break.",
        "Sip herbal tea like chamomile or peppermint in the evening.",
        "Stretch your neck and shoulders where stress often hides.",
        "Create a 'done' list to acknowledge what you accomplished.",
        "Spend time with a pet if you have one — they reduce stress.",
        "Try a guided imagery exercise: picture a calm, safe place.",
        "Limit multitasking — focus on one thing at a time.",
        "Step outside for fresh air when stress builds up.",
        "End your workday with a clear shutdown ritual.",
    ],
    # --- Energy (20) ---
    "energy": [
        "Drink a glass of water first thing in the morning.",
        "Take a short walk in natural daylight to boost alertness.",
        "Choose protein-rich snacks over sugary ones for steady energy.",
        "Stand up and stretch every hour if you're sitting a lot.",
        "A quick 5-minute movement break can refresh your energy.",
        "Prioritize your most important task when your energy is highest.",
        "Avoid skipping meals; eat something nourishing every 3–4 hours.",
        "If you drink coffee, have it earlier in the day to protect sleep.",
        "A brief power nap (10–20 minutes) can recharge without grogginess.",
        "Check if you're actually thirsty rather than tired — drink water.",
        "Eat a balanced breakfast with protein and complex carbs.",
        "Take a short walk after lunch to avoid the afternoon slump.",
        "Keep healthy snacks like nuts or fruit within reach.",
        "Adjust your workspace lighting — brighter light helps alertness.",
        "Try breathing deeply for 1 minute when you feel drained.",
        "Limit sugar crashes by pairing carbs with protein or fat.",
        "Step outside for 5 minutes of fresh air mid-afternoon.",
        "Listen to upbeat music to gently raise your energy.",
        "Alternate sitting and standing if you have a desk job.",
        "Schedule demanding tasks during your natural peak hours.",
    ],
    # --- Mood (20) ---
    "mood": [
        "Note three small things that went well today, no matter how tiny.",
        "Reach out to a friend or family member for a quick chat.",
        "Do something kind for someone else — it lifts your mood too.",
        "Spend a few minutes on a creative activity you enjoy.",
        "Get outside for fresh air, even if it's just 5 minutes.",
        "Play music that matches or gently lifts the mood you want.",
        "Be kind to yourself — difficult days are normal and temporary.",
        "Try a short guided meditation or mindfulness exercise.",
        "Write in a journal to get thoughts out of your head and onto paper.",
        "Plan one thing to look forward to this week.",
        "Take a break from screens and do something offline.",
        "Spend time near plants or nature if you can.",
        "Practice self-compassion — talk to yourself like you'd talk to a friend.",
        "Try a simple gratitude pause before meals.",
        "Dance to one song you love — movement shifts mood.",
        "Declutter one small space in your environment.",
        "Read a few pages of something uplifting or funny.",
        "Set a tiny, achievable goal for today and celebrate finishing it.",
        "Limit comparisons to others on social media.",
        "End the day by reflecting on one thing you handled well.",
    ],
    # --- Hydration (20) ---
    "hydration": [
        "Keep a water bottle within arm's reach all day.",
        "Drink a glass of water with each meal.",
        "Set a gentle reminder to sip water every couple of hours.",
        "Add a slice of lemon, cucumber, or mint if plain water feels boring.",
        "Have a glass of water when you first wake up.",
        "Drink water before you feel thirsty — thirst means you're already behind.",
        "Choose water over sugary drinks when you can.",
        "Eat water-rich foods like cucumber, watermelon, or oranges.",
        "Have a glass of water before and after exercise.",
        "Drink water between alcoholic or caffeinated drinks.",
        "Track your water intake with a simple tally or app.",
        "Start your day with a full glass of water before coffee.",
        "Keep a glass of water by your bedside at night.",
        "Choose herbal tea as a hydrating evening option.",
        "Drink water when you feel a mid-afternoon energy dip.",
        "Carry a reusable bottle when you leave the house.",
        "Drink water before meals to support digestion.",
        "Add electrolyte-rich foods like bananas or coconut water.",
        "Notice your urine color — pale yellow means you're hydrated.",
        "Make hydration a social habit — drink water with a friend.",
    ],
}

# Map each insight type to the suggestion categories it can draw from
INSIGHT_SUGGESTION_CATEGORIES: Dict[str, List[str]] = {
    "short_sleep_poor_quality": ["sleep"],
    "short_sleep": ["sleep"],
    "high_stress_low_energy": ["stress", "energy", "sleep"],
    "high_stress": ["stress"],
    "low_energy": ["energy", "sleep", "hydration"],
    "low_mood": ["mood"],
    "poor_hydration": ["hydration"],
    "restful_sleep": ["sleep"],
    "great_day": ["sleep", "stress", "energy", "mood", "hydration"],
    "sleep_change_vs_baseline": ["sleep"],
    "energy_below_baseline": ["energy", "sleep"],
    "stress_above_baseline": ["stress"],
    "mood_below_baseline": ["mood"],
}

# Total count check
_TOTAL = sum(len(v) for v in SUGGESTIONS.values())
assert _TOTAL == 100, f"Expected 100 suggestions, got {_TOTAL}"


class InsightsEngine:
    """Generates explainable wellness insights from a check-in and its history."""

    def __init__(self, history: Optional[List[Dict[str, Any]]] = None):
        self.history = history or []

    def analyze(
        self,
        check_in: Dict[str, Any],
        user_id: str,
    ) -> Dict[str, Any]:
        """Run the full analysis for a check-in."""
        insights: List[InsightItem] = []
        matched_categories: Set[str] = set()

        sleep_hours = check_in.get("sleep_duration_hours")
        sleep_q = _to_numeric(check_in.get("sleep_quality"))
        mood = _to_numeric(check_in.get("mood"))
        energy = _to_numeric(check_in.get("energy"))
        stress = _to_numeric(check_in.get("stress"))
        hydration_raw = check_in.get("hydration")
        hydration = str(hydration_raw).strip().lower() if hydration_raw else None

        # --- Rule 1: short sleep + poor sleep quality ---
        if (
            sleep_hours is not None
            and sleep_hours < SLEEP_SHORT_HOURS
            and sleep_q is not None
            and sleep_q <= SLEEP_QUALITY_POOR_THRESHOLD
        ):
            insights.append(
                InsightItem(
                    type="short_sleep_poor_quality",
                    message=(
                        f"Your sleep was {sleep_hours} hours with "
                        f"{_label(check_in.get('sleep_quality'))} reported quality. "
                        f"Short sleep combined with poor sleep quality may leave you "
                        f"feeling less rested."
                    ),
                    supporting_observations=[
                        {"field": "sleep_duration_hours", "value": sleep_hours},
                        {
                            "field": "sleep_quality",
                            "value": sleep_q,
                            "label": _label(check_in.get("sleep_quality")),
                        },
                    ],
                    severity="medium",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["short_sleep_poor_quality"])

        # --- Rule 2: short sleep only ---
        elif sleep_hours is not None and sleep_hours < SLEEP_SHORT_HOURS:
            insights.append(
                InsightItem(
                    type="short_sleep",
                    message=(
                        f"Your sleep was {sleep_hours} hours, which is below the "
                        f"recommended 7–9 hours for most adults."
                    ),
                    supporting_observations=[{"field": "sleep_duration_hours", "value": sleep_hours}],
                    severity="medium",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["short_sleep"])

        # --- Rule 3: high stress + low energy ---
        if (
            stress is not None
            and stress >= STRESS_HIGH_THRESHOLD
            and energy is not None
            and energy <= ENERGY_LOW_THRESHOLD
        ):
            insights.append(
                InsightItem(
                    type="high_stress_low_energy",
                    message=(
                        f"High stress ({_label(check_in.get('stress'))}) alongside "
                        f"low energy ({_label(check_in.get('energy'))}). "
                        f"These often track together."
                    ),
                    supporting_observations=[
                        {"field": "stress", "value": stress, "label": _label(check_in.get("stress"))},
                        {"field": "energy", "value": energy, "label": _label(check_in.get("energy"))},
                    ],
                    severity="medium",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["high_stress_low_energy"])

        # --- Rule 4: high stress only ---
        elif stress is not None and stress >= STRESS_HIGH_THRESHOLD:
            insights.append(
                InsightItem(
                    type="high_stress",
                    message=(
                        f"Your stress is recorded as {_label(check_in.get('stress'))} today."
                    ),
                    supporting_observations=[{"field": "stress", "value": stress, "label": _label(check_in.get("stress"))}],
                    severity="medium",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["high_stress"])

        # --- Rule 5: low energy only ---
        elif energy is not None and energy <= ENERGY_LOW_THRESHOLD:
            insights.append(
                InsightItem(
                    type="low_energy",
                    message=(
                        f"Your energy is recorded as {_label(check_in.get('energy'))} today."
                    ),
                    supporting_observations=[{"field": "energy", "value": energy, "label": _label(check_in.get("energy"))}],
                    severity="medium",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["low_energy"])

        # --- Rule 6: low mood ---
        if mood is not None and mood <= MOOD_LOW_THRESHOLD:
            insights.append(
                InsightItem(
                    type="low_mood",
                    message=f"Your mood is recorded as {_label(check_in.get('mood'))} today.",
                    supporting_observations=[
                        {"field": "mood", "value": mood, "label": _label(check_in.get("mood"))}
                    ],
                    severity="info",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["low_mood"])

        # --- Rule 7: poor hydration ---
        if hydration in HYDRATION_POOR_VALUES:
            insights.append(
                InsightItem(
                    type="poor_hydration",
                    message=(
                        f"Hydration is recorded as {_label(check_in.get('hydration'))}. "
                        f"Aim for regular fluids through the day."
                    ),
                    supporting_observations=[{"field": "hydration", "value": hydration}],
                    severity="low",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["poor_hydration"])

        # --- Rule 8: restful sleep (positive reinforcement) ---
        if (
            sleep_hours is not None
            and sleep_hours >= SLEEP_RESTFUL_HOURS
            and sleep_q is not None
            and sleep_q >= MOOD_GOOD_THRESHOLD
        ):
            insights.append(
                InsightItem(
                    type="restful_sleep",
                    message=(
                        f"Good sleep: {sleep_hours} hours with "
                        f"{_label(check_in.get('sleep_quality'))} quality."
                    ),
                    supporting_observations=[
                        {"field": "sleep_duration_hours", "value": sleep_hours},
                        {
                            "field": "sleep_quality",
                            "value": sleep_q,
                            "label": _label(check_in.get("sleep_quality")),
                        },
                    ],
                    severity="info",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["restful_sleep"])

        # --- Rule 9: all-green day (positive reinforcement) ---
        if (
            (sleep_hours is None or sleep_hours >= SLEEP_RESTFUL_HOURS)
            and (sleep_q is None or sleep_q >= MOOD_GOOD_THRESHOLD)
            and (mood is None or mood >= MOOD_GOOD_THRESHOLD)
            and (energy is None or energy >= ENERGY_HIGH_THRESHOLD)
            and (stress is None or stress <= ENERGY_LOW_THRESHOLD)
            and (hydration is None or hydration not in HYDRATION_POOR_VALUES)
        ):
            insights.append(
                InsightItem(
                    type="great_day",
                    message=(
                        "Everything looks balanced today — good sleep, mood, energy, "
                        "low stress, and solid hydration."
                    ),
                    supporting_observations=[
                        {"field": "sleep_duration_hours", "value": sleep_hours},
                        {"field": "sleep_quality", "value": sleep_q},
                        {"field": "mood", "value": mood},
                        {"field": "energy", "value": energy},
                        {"field": "stress", "value": stress},
                        {"field": "hydration", "value": hydration},
                    ],
                    severity="info",
                )
            )
            matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES["great_day"])

        # --- Historical comparisons vs personal baseline ---
        hist = self._historical_comparison(check_in)
        insights.extend(hist["insights"])
        for ins_type in ["sleep_change_vs_baseline", "energy_below_baseline", "stress_above_baseline", "mood_below_baseline"]:
            if ins_type in INSIGHT_SUGGESTION_CATEGORIES:
                matched_categories.update(INSIGHT_SUGGESTION_CATEGORIES[ins_type])

        # Collect applicable suggestions from matched categories
        applicable: List[str] = []
        for cat in matched_categories:
            applicable.extend(SUGGESTIONS.get(cat, []))

        # De-duplicate while preserving order
        seen: Set[str] = set()
        unique_applicable: List[str] = []
        for s in applicable:
            if s not in seen:
                seen.add(s)
                unique_applicable.append(s)

        # Randomly select 3-4 suggestions
        if unique_applicable:
            n = min(len(unique_applicable), random.choice([3, 4]))
            selected_suggestions = random.sample(unique_applicable, n)
        else:
            selected_suggestions = []

        return {
            "insights": [i.model_dump() for i in insights],
            "suggestions": selected_suggestions,
            "sample_size": len(self.history) + 1,
            "historical_trends": hist["trends"],
        }

    def _historical_comparison(
        self, check_in: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Compare the current check-in against the user's personal baseline."""
        insights: List[InsightItem] = []
        trends: Dict[str, Any] = {}

        recent = self.history[-BASELINE_WINDOW_DAYS:] if self.history else []

        def series(field: str) -> List[float]:
            out: List[float] = []
            for r in recent:
                v = _to_numeric(r.get(field))
                if v is not None:
                    out.append(v)
            return out

        # Sleep vs baseline
        prev_sleep = series("sleep_duration_hours")
        curr_sleep = check_in.get("sleep_duration_hours")
        if prev_sleep and curr_sleep is not None:
            avg = sum(prev_sleep) / len(prev_sleep)
            trends["sleep_baseline_avg"] = round(avg, 1)
            trends["sleep_sample_size"] = len(prev_sleep)
            diff = float(curr_sleep) - avg
            if abs(diff) >= 1.0:
                direction = "longer" if diff > 0 else "shorter"
                insights.append(
                    InsightItem(
                        type="sleep_change_vs_baseline",
                        message=(
                            f"Today's sleep ({curr_sleep}h) is {direction} than your "
                            f"{len(prev_sleep)}-day average ({avg:.1f}h)."
                        ),
                        supporting_observations=[
                            {"field": "sleep_duration_hours", "value": curr_sleep},
                            {"field": "sleep_baseline_avg", "value": round(avg, 1)},
                        ],
                        severity="low",
                    )
                )

        # Energy vs baseline
        prev_energy = series("energy")
        curr_energy = _to_numeric(check_in.get("energy"))
        if prev_energy and curr_energy is not None:
            avg = sum(prev_energy) / len(prev_energy)
            trends["energy_baseline_avg"] = round(avg, 1)
            if curr_energy <= avg - 2:
                insights.append(
                    InsightItem(
                        type="energy_below_baseline",
                        message=(
                            f"Your energy ({_label(check_in.get('energy'))}) is below "
                            f"your recent average."
                        ),
                        supporting_observations=[
                            {"field": "energy", "value": curr_energy},
                            {"field": "energy_baseline_avg", "value": round(avg, 1)},
                        ],
                        severity="low",
                    )
                )

        # Stress vs baseline
        prev_stress = series("stress")
        curr_stress = _to_numeric(check_in.get("stress"))
        if prev_stress and curr_stress is not None:
            avg = sum(prev_stress) / len(prev_stress)
            trends["stress_baseline_avg"] = round(avg, 1)
            if curr_stress >= avg + 2:
                insights.append(
                    InsightItem(
                        type="stress_above_baseline",
                        message=(
                            f"Your stress ({_label(check_in.get('stress'))}) is above "
                            f"your recent average."
                        ),
                        supporting_observations=[
                            {"field": "stress", "value": curr_stress},
                            {"field": "stress_baseline_avg", "value": round(avg, 1)},
                        ],
                        severity="low",
                    )
                )

        # Mood vs baseline
        prev_mood = series("mood")
        curr_mood = _to_numeric(check_in.get("mood"))
        if prev_mood and curr_mood is not None:
            avg = sum(prev_mood) / len(prev_mood)
            trends["mood_baseline_avg"] = round(avg, 1)
            if curr_mood <= avg - 2:
                insights.append(
                    InsightItem(
                        type="mood_below_baseline",
                        message=(
                            f"Your mood ({_label(check_in.get('mood'))}) is below "
                            f"your recent average."
                        ),
                        supporting_observations=[
                            {"field": "mood", "value": curr_mood},
                            {"field": "mood_baseline_avg", "value": round(avg, 1)},
                        ],
                        severity="low",
                    )
                )

        return {"insights": insights, "trends": trends}
