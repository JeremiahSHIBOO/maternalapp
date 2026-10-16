"""Rules-based wellness insights engine.

Transparent and explainable. Produces observations and suggestions only;
never a medical diagnosis or causal claim. Thresholds are documented in
core.thresholds and configurable via environment variables.
"""
from __future__ import annotations
from typing import Any, Dict, List, Optional

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
    """Map a categorical string or numeric to the 1-10 scale."""
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return SCORE_MAP.get(str(value).strip().lower())


def _label(value: Any) -> Optional[str]:
    if value is None:
        return None
    return str(value)


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
                    suggested_action=(
                        "Consider a consistent wind-down routine and limiting screens before bed."
                    ),
                    severity="medium",
                )
            )

        # --- Rule 2: high stress + low energy ---
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
                    suggested_action=(
                        "Try short breathing breaks or gentle movement during the day."
                    ),
                    severity="medium",
                )
            )

        # --- Rule 3: low mood ---
        if mood is not None and mood <= MOOD_LOW_THRESHOLD:
            insights.append(
                InsightItem(
                    type="low_mood",
                    message=f"Your mood is recorded as {_label(check_in.get('mood'))} today.",
                    supporting_observations=[
                        {"field": "mood", "value": mood, "label": _label(check_in.get("mood"))}
                    ],
                    suggested_action=(
                        "Consider noting what may be affecting your mood in your journal."
                    ),
                    severity="info",
                )
            )

        # --- Rule 4: poor hydration ---
        if hydration in HYDRATION_POOR_VALUES:
            insights.append(
                InsightItem(
                    type="poor_hydration",
                    message=(
                        f"Hydration is recorded as {_label(check_in.get('hydration'))}. "
                        f"Aim for regular fluids through the day."
                    ),
                    supporting_observations=[{"field": "hydration", "value": hydration}],
                    suggested_action=("Keep water nearby and sip regularly."),
                    severity="low",
                )
            )

        # --- Rule 5: restful sleep (positive reinforcement) ---
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
                    suggested_action=("Keep your current sleep routine."),
                    severity="info",
                )
            )

        # --- Historical comparisons vs personal baseline ---
        hist = self._historical_comparison(check_in)
        insights.extend(hist["insights"])

        # De-duplicate and de-contradict suggestions while preserving order.
        suggestions: List[str] = []
        seen = set()
        for ins in insights:
            action = ins.suggested_action
            if action and action not in seen:
                seen.add(action)
                suggestions.append(action)

        return {
            "insights": [i.model_dump() for i in insights],
            "suggestions": suggestions,
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
                        suggested_action=(
                            "Notice what differs on shorter-sleep days and adjust where you can."
                        ),
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
                        suggested_action=(
                            "Prioritize rest and lighter activity today if possible."
                        ),
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
                        suggested_action=(
                            "Consider a calming activity you find helpful."
                        ),
                        severity="low",
                    )
                )

        return {"insights": insights, "trends": trends}
