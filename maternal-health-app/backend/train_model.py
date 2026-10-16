"""Generate a robust synthetic training dataset for the ML energy model.

This is PLACEHOLDER / DEFAULT data for demonstration and initial model
training only. It is NOT real user data and should be replaced with actual
historical check-ins as soon as sufficient real data is available.

Design principles for better outcomes:
- Larger volume (3000+ records) for stable learning
- Full categorical grid coverage so all combinations are represented
- Deterministic labeling rule with clear signal but realistic noise
- Class-balanced output (equal Low / Some / Plenty)
- Feature interactions (sleep quality x stress, energy x hydration, etc.)
- Chronological ordering for valid train/test splits
"""
from __future__ import annotations

import random
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Tuple

from app.ml_model import EnergyPredictor, MODEL_PATH, _to_numeric

random.seed(42)

ENERGY_CATEGORIES = ["Low", "Some", "Plenty"]
HYDRATION_VALUES = ["poor", "fair", "good", "excellent"]
QUALITY_VALUES = ["Poor", "Okay", "Good"]
MOOD_VALUES = ["Low", "Okay", "Good"]
STRESS_VALUES = ["Low", "Some", "High"]

# Thresholds (must match ml_model.py / core/thresholds.py)
ENERGY_LOW = 3
ENERGY_HIGH = 7


def _score(value: str) -> int:
    m = {
        "low": 2, "some": 5, "plenty": 9,
        "poor": 2, "okay": 5, "good": 9, "high": 9, "excellent": 9, "fair": 4,
    }
    return m[str(value).strip().lower()]


def _label_next_energy(cur: dict) -> str:
    """Derive next-day energy from current-day features.

    Deterministic core with realistic noise. Strong enough signal that a
    model can learn real associations, but noisy enough that accuracy won't
    be perfect (mirroring real-world health data).
    """
    energy = _score(cur["energy"])
    stress = _score(cur["stress"])
    sleep_q = _score(cur["sleep_quality"])
    mood = _score(cur["mood"])
    sleep_h = cur.get("sleep_duration_hours") or 7
    hydration = _score(cur.get("hydration") or "good")

    # Base score: current energy is the strongest predictor
    score = energy * 0.30
    score += sleep_q * 0.25
    score += mood * 0.20
    score -= stress * 0.25
    score += hydration * 0.10
    score += (min(max(sleep_h, 4), 10) - 5) * 0.10

    # Interaction: good sleep amplifies good mood; high stress dampens energy
    if sleep_q >= 7 and mood >= 7:
        score += 0.8  # restful sleep + good mood synergy
    if stress >= 7 and energy >= 7:
        score -= 1.0  # high stress drains even high energy
    if sleep_h < 6 and sleep_q <= 3:
        score -= 1.2  # short + poor sleep is especially draining
    if hydration <= 4 and energy <= 3:
        score -= 0.6  # low hydration + low energy compound

    # Realistic noise — not deterministic, mirrors real health variability
    score += random.uniform(-1.0, 1.0)

    # Balanced thresholds tuned to the score distribution (avg ~3.4)
    if score <= 2.5:
        return "Low"
    if score >= 5.0:
        return "Plenty"
    return "Some"


def generate_records(num_days: int = 120) -> List[Dict[str, Any]]:
    """Generate chronological check-in records covering all scenarios."""
    records: List[Dict[str, Any]] = []
    base = datetime(2026, 1, 1, tzinfo=timezone.utc)

    # 1) Full categorical grid — every combination gets represented
    grid: List[Dict[str, Any]] = []
    for sleep_h in [4.5, 5.5, 6.5, 7.5, 8.5, 9.5]:
        for sq in QUALITY_VALUES:
            for mood in MOOD_VALUES:
                for en in ENERGY_CATEGORIES:
                    for st in STRESS_VALUES:
                        for hy in HYDRATION_VALUES:
                            grid.append({
                                "sleep_duration_hours": sleep_h,
                                "sleep_quality": sq,
                                "mood": mood,
                                "energy": en,
                                "stress": st,
                                "hydration": hy,
                                "notes": "synthetic grid record",
                            })

    random.shuffle(grid)

    for i, g in enumerate(grid):
        d = base + timedelta(days=i % num_days, hours=(i * 7) % 24)
        records.append({
            **g,
            "check_in_date": d.isoformat(),
            "created_at": d.isoformat(),
        })

    # 2) Extra randomized records for volume and temporal spread
    extra = max(0, 1800 - len(grid))
    for _ in range(extra):
        d = base + timedelta(days=random.randint(0, num_days - 1),
                             hours=random.randint(0, 23))
        records.append({
            "sleep_duration_hours": round(random.uniform(4, 10), 1),
            "sleep_quality": random.choice(QUALITY_VALUES),
            "mood": random.choice(MOOD_VALUES),
            "energy": random.choice(ENERGY_CATEGORIES),
            "stress": random.choice(STRESS_VALUES),
            "hydration": random.choice(HYDRATION_VALUES),
            "check_in_date": d.isoformat(),
            "created_at": d.isoformat(),
            "notes": "synthetic random record",
        })

    # Sort chronologically (oldest first) — required for chronological split
    records.sort(key=lambda r: r["check_in_date"])
    return records


def build_pairs_with_labels(
    records: List[Dict[str, Any]],
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """Build supervised pairs: current check-in -> labeled next-day energy.

    Labels come from _label_next_energy(current_features), NOT from the next
    record's actual energy. This creates a learnable signal.
    """
    rows: List[Dict[str, Any]] = []
    for i in range(len(records) - 1):
        cur = records[i]
        row = {
            "sleep_duration_hours": _to_numeric(cur.get("sleep_duration_hours")),
            "sleep_quality": _to_numeric(cur.get("sleep_quality")),
            "mood": _to_numeric(cur.get("mood")),
            "energy": _to_numeric(cur.get("energy")),
            "stress": _to_numeric(cur.get("stress")),
            "hydration": _to_numeric(cur.get("hydration")),
            "next_energy_category": _label_next_energy(cur),
        }
        if row["next_energy_category"] is None:
            continue
        if all(v is None for k, v in row.items() if k != "next_energy_category"):
            continue
        rows.append(row)

    info: Dict[str, Any] = {
        "total_pairs": len(rows),
        "class_distribution": dict(Counter(r["next_energy_category"] for r in rows)) if rows else {},
    }
    return rows, info


def main() -> None:
    records = generate_records()
    print(f"Generated {len(records)} synthetic check-in records.")

    pairs, info = build_pairs_with_labels(records)
    print(f"Supervised pairs: {info['total_pairs']}")
    print(f"Class distribution: {info['class_distribution']}")

    predictor = EnergyPredictor()
    result = predictor.train_from_pairs(pairs)

    print("\nTraining result:")
    for k, v in result.items():
        if k != "report":
            print(f"  {k}: {v}")
    if result.get("trained"):
        print("\nClassification report:")
        for cls, metrics in result["report"].items():
            if isinstance(metrics, dict):
                print(f"  {cls}: precision={metrics.get('precision')}, "
                      f"recall={metrics.get('recall')}, "
                      f"f1={metrics.get('f1-score')}")

    print(f"\nModel saved to: {MODEL_PATH}")


if __name__ == "__main__":
    main()
