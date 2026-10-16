"""Optional ML prediction pipeline for next-day energy category.

Starts as a rules-based fallback. Trains scikit-learn models only when
sufficient historical data exists. Chronological train/test split, no
leakage, calibrated probabilities only after validation.
"""
from __future__ import annotations
import os
from collections import Counter
from typing import Any, Dict, List, Optional, Tuple

import joblib
import numpy as np

from .core.thresholds import (
    SCORE_MAP,
    ENERGY_LOW_THRESHOLD,
    ENERGY_HIGH_THRESHOLD,
    MIN_TRAINING_RECORDS,
)

MODEL_PATH = os.getenv("WELLNESS_ML_MODEL_PATH", "wellness_energy_model.joblib")

ENERGY_CATEGORIES = ["Low", "Some", "Plenty"]


def _to_numeric(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return SCORE_MAP.get(str(value).strip().lower())


def _energy_category(value: Any) -> Optional[str]:
    n = _to_numeric(value)
    if n is None:
        return None
    if n <= ENERGY_LOW_THRESHOLD:
        return "Low"
    if n >= ENERGY_HIGH_THRESHOLD:
        return "Plenty"
    return "Some"


def build_dataset(
    records: List[Dict[str, Any]],
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """Build chronological supervised pairs: today's check-in -> tomorrow's energy category.

    Record i predicts record i+1. No leakage: training and test sets are split
    chronologically.
    """
    rows: List[Dict[str, Any]] = []
    for i in range(len(records) - 1):
        cur = records[i]
        nxt = records[i + 1]
        row = {
            "sleep_duration_hours": _to_numeric(cur.get("sleep_duration_hours")),
            "sleep_quality": _to_numeric(cur.get("sleep_quality")),
            "mood": _to_numeric(cur.get("mood")),
            "energy": _to_numeric(cur.get("energy")),
            "stress": _to_numeric(cur.get("stress")),
            "hydration": _to_numeric(cur.get("hydration")),
            "next_energy_category": _energy_category(nxt.get("energy")),
        }
        if row["next_energy_category"] is None:
            continue
        if all(v is None for k, v in row.items() if k != "next_energy_category"):
            continue
        rows.append(row)

    info: Dict[str, Any] = {
        "total_pairs": len(rows),
        "class_distribution": (
            dict(Counter(r["next_energy_category"] for r in rows)) if rows else {}
        ),
    }
    return rows, info


class EnergyPredictor:
    """Trains and predicts next-day energy category. Falls back to rules."""

    def __init__(self) -> None:
        self.model = None
        self.model_available = False
        self.calibrated = False

    def load(self) -> bool:
        if os.path.exists(MODEL_PATH):
            try:
                self.model = joblib.load(MODEL_PATH)
                self.model_available = True
                self.calibrated = hasattr(self.model, "calibrated_classifiers_")
                return True
            except Exception:
                self.model_available = False
                return False
        return False

    def train(self, records: List[Dict[str, Any]]) -> Dict[str, Any]:
        rows, info = build_dataset(records)
        if len(rows) < MIN_TRAINING_RECORDS:
            return {
                "trained": False,
                "reason": (
                    f"Insufficient data: {len(rows)} pairs, need "
                    f"{MIN_TRAINING_RECORDS}. Rules-based fallback will be used."
                ),
                "info": info,
            }

        # Chronological split: first 80% train, last 20% test.
        split = int(len(rows) * 0.8)
        train_rows = rows[:split]
        test_rows = rows[split:]
        if not test_rows:
            test_rows = train_rows

        X_train, y_train = self._xy(train_rows)
        X_test, y_test = self._xy(test_rows)

        from sklearn.linear_model import LogisticRegression
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.calibration import CalibratedClassifierCV
        from sklearn.metrics import classification_report, confusion_matrix
        from sklearn.preprocessing import StandardScaler
        from sklearn.impute import SimpleImputer
        from sklearn.pipeline import Pipeline

        # Baseline: majority class.
        majority = Counter(y_train).most_common(1)[0][0]
        baseline_acc = (
            sum(1 for y in y_test if y == majority) / len(y_test) if y_test else 0.0
        )

        imputer = SimpleImputer(strategy="median")
        Xtr = imputer.fit_transform(X_train)
        Xte = imputer.transform(X_test)

        models = {
            "logistic_regression": LogisticRegression(
                max_iter=1000, class_weight="balanced"
            ),
            "random_forest": RandomForestClassifier(
                n_estimators=100, class_weight="balanced", random_state=42
            ),
        }
        best = None
        best_name = None
        best_score = -1.0
        results: Dict[str, Any] = {}
        for name, clf in models.items():
            pipe = Pipeline([("scale", StandardScaler()), ("clf", clf)])
            pipe.fit(Xtr, y_train)
            acc = pipe.score(Xte, y_test)
            results[name] = {"accuracy": round(acc, 3)}
            if acc > best_score:
                best_score = acc
                best = pipe
                best_name = name

        # Calibrate only when feasible.
        try:
            cal = CalibratedClassifierCV(best, method="isotonic", cv=3)
            cal.fit(Xtr, y_train)
            self.model = cal
            self.calibrated = True
        except Exception:
            self.model = best
            self.calibrated = False

        self.model_available = True
        try:
            joblib.dump(self.model, MODEL_PATH)
        except Exception:
            pass

        report = classification_report(
            y_test, self.model.predict(Xte), output_dict=True, zero_division=0
        )
        return {
            "trained": True,
            "model": best_name,
            "calibrated": self.calibrated,
            "test_accuracy": round(best_score, 3),
            "baseline_accuracy": round(baseline_acc, 3),
            "per_model": results,
            "report": report,
            "confusion_matrix": confusion_matrix(
                y_test, self.model.predict(Xte), labels=ENERGY_CATEGORIES
            ).tolist(),
            "info": info,
        }

    def _xy(self, rows: List[Dict[str, Any]]) -> Tuple[np.ndarray, List[str]]:
        X = []
        y = []
        for r in rows:
            X.append(
                [
                    r["sleep_duration_hours"],
                    r["sleep_quality"],
                    r["mood"],
                    r["energy"],
                    r["stress"],
                    r["hydration"],
                ]
            )
            y.append(r["next_energy_category"])
        return np.array(X, dtype=float), y

    def predict(self, current: Dict[str, Any]) -> Dict[str, Any]:
        """Predict next-day energy category from the current check-in."""
        if not self.model_available or self.model is None:
            return self._fallback(current)

        X = np.array(
            [
                [
                    _to_numeric(current.get("sleep_duration_hours")),
                    _to_numeric(current.get("sleep_quality")),
                    _to_numeric(current.get("mood")),
                    _to_numeric(current.get("energy")),
                    _to_numeric(current.get("stress")),
                    _to_numeric(current.get("hydration")),
                ]
            ],
            dtype=float,
        )
        try:
            pred = self.model.predict(X)[0]
            prob: Optional[float] = None
            if self.calibrated and hasattr(self.model, "predict_proba"):
                proba = self.model.predict_proba(X)[0]
                prob = float(max(proba))
            return {
                "prediction": str(pred),
                "probability": prob,
                "model_available": True,
                "fallback": False,
                "message": (
                    "ML prediction (calibrated)"
                    if self.calibrated
                    else "ML prediction (uncalibrated)"
                ),
            }
        except Exception:
            return self._fallback(current)

    def _fallback(self, current: Dict[str, Any]) -> Dict[str, Any]:
        energy = _to_numeric(current.get("energy"))
        if energy is None:
            cat = "Some"
        elif energy <= ENERGY_LOW_THRESHOLD:
            cat = "Low"
        elif energy >= ENERGY_HIGH_THRESHOLD:
            cat = "Plenty"
        else:
            cat = "Some"
        return {
            "prediction": cat,
            "probability": None,
            "model_available": False,
            "fallback": True,
            "message": "No trained model; using rules-based fallback.",
        }
