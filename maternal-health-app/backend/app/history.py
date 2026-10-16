"""Historical trend analysis for wellness check-ins.

Calendar-day aware. De-duplicates same-day submissions. Reports sample sizes
and missing-data rates. Describes associations only, never causes.
"""
from __future__ import annotations
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from collections import Counter

from .core.thresholds import (
    MIN_OBSERVATIONS_7DAY,
    MIN_OBSERVATIONS_30DAY,
    SCORE_MAP,
)


def _to_date(value: Any) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.astimezone(timezone.utc).date().isoformat()
    if isinstance(value, str):
        return value[:10]
    return None


def _to_numeric(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return SCORE_MAP.get(str(value).strip().lower())


def analyze_history(
    records: List[Dict[str, Any]],
    user_id: str,
) -> Dict[str, Any]:
    """Compute 7-day and 30-day summaries from ordered check-in records.

    `records` should be oldest -> newest. Each record is a dict with at least
    check_in_date plus the wellness fields.
    """
    today = datetime.now(timezone.utc).date()

    # De-duplicate same-day submissions: keep the latest per calendar day.
    by_day: Dict[str, Dict[str, Any]] = {}
    for rec in records:
        d = _to_date(rec.get("check_in_date") or rec.get("created_at"))
        if d is None:
            continue
        created = rec.get("created_at", "")
        if d not in by_day or created >= by_day[d].get("created_at", ""):
            by_day[d] = rec
    deduped = sorted(
        by_day.values(),
        key=lambda r: _to_date(r.get("check_in_date") or r.get("created_at")) or "",
    )

    sample_size = len(deduped)

    def window(days: int) -> List[Dict[str, Any]]:
        cutoff = (today - timedelta(days=days - 1)).isoformat()
        return [
            r
            for r in deduped
            if (_to_date(r.get("check_in_date") or r.get("created_at")) or "")
            >= cutoff
        ]

    def summarize(days: int, min_obs: int) -> Optional[Dict[str, Any]]:
        w = window(days)
        n = len(w)
        reliable = n >= min_obs
        if not reliable:
            return {
                "days": days,
                "observations": n,
                "reliable": False,
                "message": (
                    f"Only {n} observation(s) in the last {days} days; "
                    f"need at least {min_obs} for a reliable summary."
                ),
            }

        sleeps = [
            _to_numeric(r.get("sleep_duration_hours"))
            for r in w
            if r.get("sleep_duration_hours") is not None
        ]
        avg_sleep = round(sum(sleeps) / len(sleeps), 1) if sleeps else None

        def dist(field: str) -> Dict[str, int]:
            cnt = Counter()
            for r in w:
                v = r.get(field)
                if v is None:
                    continue
                cnt[str(v).strip().lower()] += 1
            return dict(cnt)

        missing = {
            "sleep_duration_hours": sum(
                1 for r in w if r.get("sleep_duration_hours") is None
            )
            / n,
            "sleep_quality": sum(1 for r in w if r.get("sleep_quality") is None) / n,
            "mood": sum(1 for r in w if r.get("mood") is None) / n,
            "energy": sum(1 for r in w if r.get("energy") is None) / n,
            "stress": sum(1 for r in w if r.get("stress") is None) / n,
            "hydration": sum(1 for r in w if r.get("hydration") is None) / n,
        }

        return {
            "days": days,
            "observations": n,
            "reliable": True,
            "average_sleep_hours": avg_sleep,
            "sleep_distribution": dist("sleep_quality"),
            "mood_distribution": dist("mood"),
            "energy_distribution": dist("energy"),
            "stress_distribution": dist("stress"),
            "hydration_distribution": dist("hydration"),
            "missing_data_rates": {k: round(v, 2) for k, v in missing.items()},
        }

    seven_day = summarize(7, MIN_OBSERVATIONS_7DAY)
    thirty_day = summarize(30, MIN_OBSERVATIONS_30DAY)

    # Baseline: prefer 30-day reliable, else 7-day reliable, else all available.
    baseline_records: List[Dict[str, Any]] = []
    if thirty_day and thirty_day["reliable"]:
        baseline_records = window(30)
    elif seven_day and seven_day["reliable"]:
        baseline_records = window(7)
    else:
        baseline_records = deduped

    # Associations between variables (described as association, not cause)
    associations: List[Dict[str, Any]] = []
    if len(baseline_records) >= 5:
        pairs = [
            ("sleep_duration_hours", "energy"),
            ("stress", "energy"),
            ("sleep_quality", "mood"),
            ("hydration", "energy"),
        ]
        for a, b in pairs:
            xa: List[float] = []
            ya: List[float] = []
            for r in deduped:
                va = _to_numeric(r.get(a))
                vb = _to_numeric(r.get(b))
                if va is not None and vb is not None:
                    xa.append(va)
                    ya.append(vb)
            if len(xa) >= 5:
                assoc = _association_strength(xa, ya)
                associations.append(
                    {
                        "variable_a": a,
                        "variable_b": b,
                        "observations": len(xa),
                        "association": assoc["label"],
                        "note": "Association only — not a causal claim.",
                    }
                )

    missing_rates: Dict[str, float] = {}
    if thirty_day and thirty_day.get("missing_data_rates"):
        missing_rates = thirty_day["missing_data_rates"]
    elif seven_day and seven_day.get("missing_data_rates"):
        missing_rates = seven_day["missing_data_rates"]

    return {
        "user_id": user_id,
        "seven_day": seven_day,
        "thirty_day": thirty_day,
        "sample_size": sample_size,
        "associations": associations,
        "missing_data_rates": missing_rates,
    }


def _association_strength(x: List[float], y: List[float]) -> Dict[str, Any]:
    """Simple Pearson-style strength bucket. No causation implied."""
    n = len(x)
    mx = sum(x) / n
    my = sum(y) / n
    num = sum((a - mx) * (b - my) for a, b in zip(x, y))
    dx = sum((a - mx) ** 2 for a in x) ** 0.5
    dy = sum((b - my) ** 2 for b in y) ** 0.5
    r = num / (dx * dy) if dx and dy else 0.0
    abs_r = abs(r)
    if abs_r >= 0.7:
        label = "strong"
    elif abs_r >= 0.4:
        label = "moderate"
    elif abs_r >= 0.15:
        label = "weak"
    else:
        label = "none"
    direction = "positive" if r > 0 else ("negative" if r < 0 else "neutral")
    return {"r": round(r, 2), "label": f"{direction} {label}"}
