"""Generate a synthetic training dataset covering all wellness scenarios.

This is PLACEHOLDER / DEFAULT data for demonstration and initial model
training only. It is NOT real user data and should be replaced with actual
historical check-ins as soon as sufficient real data is available.

Covers all combinations of:
- Sleep duration: short (5-6h), normal (7-8h), long (9h+)
- Sleep quality: Poor, Okay, Good
- Mood: Low, Okay, Good
- Energy: Low, Some, Plenty
- Stress: Low, Some, High
- Hydration: poor, fair, good, excellent

Labels (next-day energy category) are derived from current-day features with
added noise so the model has a learnable signal. Documented as synthetic.
"""
from __future__ import annotations

import random
from datetime import datetime, timedelta, timezone
from typing import Any

from app.ml_model import build_dataset, EnergyPredictor

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
    """Derive a plausible next-day energy label from current-day features.

    Synthetic labeling rule with noise — clearly a placeholder until real
    labeled data exists.
    """
    energy = _score(cur["energy"])
    stress = _score(cur["stress"])
    sleep_q = _score(cur["sleep_quality"])
    mood = _score(cur["mood"])

    # Base score: energy up, stress/sleep down
    base = energy - stress * 0.4 + sleep_q * 0.3 + mood * 0.2
    base += random.uniform(-1.5, 1.5)  # noise

    if base <= 4.0:
        return "Low"
    if base >= 7.0:
        return "Plenty"
    return "Some"


def generate_records(num_days: int = 120) -> list[dict[str, Any]]:
    """Generate chronological check-in records covering all scenarios."""
    records: list[dict[str, Any]] = []
    base = datetime(2026, 1, 1, tzinfo=timezone.utc)

    # Ensure full coverage of the categorical grid first.
    grid: list[dict[str, Any]] = []
    for sleep_h in [5.0, 6.0, 7.0, 8.0, 9.0]:
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

    # Add extra random records to reach a realistic volume and temporal spread.
    extra = max(0, 300 - len(grid))
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

    # Sort chronologically (oldest first) — required for chronological split.
    records.sort(key=lambda r: r["check_in_date"])
    return records


def main() -> None:
    records = generate_records()
    print(f"Generated {len(records)} synthetic check-in records.")

    pairs, info = build_dataset(records)
    print(f"Supervised pairs: {info['total_pairs']}")
    print(f"Class distribution: {info['class_distribution']}")

    predictor = EnergyPredictor()
    result = predictor.train(records)

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

    print(f"\nModel saved to: {EnergyPredictor.__init__.__defaults__ if False else 'wellness_energy_model.joblib'}")
    from app.ml_model import MODEL_PATH
    print(f"Model path: {MODEL_PATH}")


if __name__ == "__main__":
    main()
