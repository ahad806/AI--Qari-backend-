"""
Services package
"""

from .transcription import TranscriptionService, get_transcription_service
from .tajweed_checker import TajweedChecker, get_tajweed_checker

__all__ = [
    'TranscriptionService',
    'get_transcription_service',
    'TajweedChecker',
    'get_tajweed_checker'
]
