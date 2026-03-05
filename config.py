"""
Configuration settings for AI Qaari API
"""

import os
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).resolve().parent

# Data directories
DATA_DIR = BASE_DIR / "data"
AUDIO_DIR = DATA_DIR / "audio"

# Model settings
WHISPER_MODEL = "OdyAsh/faster-whisper-base-ar-quran"  # Quran-specific Whisper model
SAMPLE_RATE = 16000

# Tajweed thresholds (can be tuned based on Qari validation)
TAJWEED_THRESHOLDS = {
    "madd": {
        "madd_asli":  (0.25, 0.90),     # 2 harakaat: 0.5s, generous ±0.35s tolerance
        "madd_wajib": (0.55, 1.30),     # 4-5 harakaat: wider range for natural variation
        "madd_lazim": (1.00, 2.00)      # 6 harakaat: wider range for natural variation
    },
    "qalqalah": {
        "intensity_spike_threshold": 0.20  # 20% intensity spike
    },
    "ghunnah": {
        "nasal_threshold": 0.30,           # 30% nasal energy
        "duration": (0.35, 0.65)           # 2 harakaat
    }
}

# API settings
MAX_AUDIO_SIZE_MB = 10
ALLOWED_AUDIO_FORMATS = ['.wav', '.mp3', '.m4a']

# Create directories if they don't exist
DATA_DIR.mkdir(exist_ok=True)
AUDIO_DIR.mkdir(exist_ok=True)
