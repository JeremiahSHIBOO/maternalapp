"""Configurable thresholds for the wellness insights engine.

All thresholds are documented as heuristic rules, not medical diagnostics.
Override via environment variables where indicated.
"""
import os

# --- Sleep thresholds (hours) ---
SLEEP_SHORT_HOURS = float(os.getenv("WELLNESS_SLEEP_SHORT_HOURS", "6.0"))
SLEEP_RESTFUL_HOURS = float(os.getenv("WELLNESS_SLEEP_RESTFUL_HOURS", "7.0"))

# --- 1-10 scale thresholds ---
# Flutter ChoiceChip maps: Low/Poor=2, Okay/Some=5, Good/Plenty/High=9
SLEEP_QUALITY_POOR_THRESHOLD = int(os.getenv("WELLNESS_SLEEP_QUALITY_POOR", "3"))
STRESS_HIGH_THRESHOLD = int(os.getenv("WELLNESS_STRESS_HIGH", "7"))
ENERGY_LOW_THRESHOLD = int(os.getenv("WELLNESS_ENERGY_LOW", "3"))
ENERGY_HIGH_THRESHOLD = int(os.getenv("WELLNESS_ENERGY_HIGH", "7"))
MOOD_LOW_THRESHOLD = int(os.getenv("WELLNESS_MOOD_LOW", "3"))
MOOD_GOOD_THRESHOLD = int(os.getenv("WELLNESS_MOOD_GOOD", "7"))

# --- Hydration ---
HYDRATION_POOR_VALUES = {"poor", "fair"}

# --- Historical baselines ---
MIN_OBSERVATIONS_7DAY = int(os.getenv("WELLNESS_MIN_OBS_7DAY", "3"))
MIN_OBSERVATIONS_30DAY = int(os.getenv("WELLNESS_MIN_OBS_30DAY", "10"))
BASELINE_WINDOW_DAYS = int(os.getenv("WELLNESS_BASELINE_WINDOW_DAYS", "30"))

# --- ML data gates ---
MIN_TRAINING_RECORDS = int(os.getenv("WELLNESS_ML_MIN_RECORDS", "60"))
MIN_DAYS_HISTORY = int(os.getenv("WELLNESS_ML_MIN_DAYS", "30"))

# --- Categorical -> numeric mapping (1-10 scale) ---
SCORE_MAP = {
    "low": 2,
    "some": 5,
    "plenty": 9,
    "poor": 2,
    "okay": 5,
    "good": 9,
    "high": 9,
    "excellent": 9,
    "fair": 4,
}
