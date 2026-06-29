"""
Tajweed rule checking service (Rule-based Phase 1)
Uses LibROSA for acoustic analysis (praat-parselmouth removed to avoid C++ build dependencies)
"""

import librosa
import numpy as np
from scipy import signal
from typing import List, Dict, Tuple, Optional
from models.schemas import TajweedError
from config import TAJWEED_THRESHOLDS, SAMPLE_RATE


class TajweedChecker:
    """
    Rule-based Tajweed error detection (MVP - Phase 1)
    Uses acoustic analysis to detect Madd, Qalqalah, and Ghunnah errors
    """
    
    def __init__(self):
        """
        Initialize Tajweed checker with thresholds
        """
        self.sample_rate = SAMPLE_RATE
        self.thresholds = TAJWEED_THRESHOLDS
        
        print("✅ Tajweed checker initialized (using LibROSA)")
    
    def check_madd(
        self,
        audio_segment: np.ndarray,
        madd_type: str,
        word: str,
        position: int
    ) -> Optional[Dict]:
        """
        Check if Madd (vowel elongation) is correct
        
        Args:
            audio_segment: Audio numpy array for the word
            madd_type: 'madd_asli', 'madd_wajib', or 'madd_lazim'
            word: Arabic word containing Madd
            position: Position in ayah
        
        Returns:
            Dictionary with error details or None if correct
        """
        # Calculate duration
        duration = len(audio_segment) / self.sample_rate
        
        # Get expected range
        min_dur, max_dur = self.thresholds['madd'].get(
            madd_type,
            self.thresholds['madd']['madd_asli']
        )
        expected = (min_dur + max_dur) / 2
        
        # Check if within tolerance
        if duration < min_dur:
            return {
                "has_error": True,
                "rule_type": "MADD",
                "word": word,
                "position": position,
                "error_message_en": f"Madd too short ({duration:.2f}s, should be {expected:.2f}s)",
                "error_message_ur": f"مد بہت چھوٹی ہے - {duration:.2f} سیکنڈ، {expected:.2f} ہونی چاہیے",
                "measured_value": round(duration, 2),
                "expected_value": round(expected, 2),
                "confidence": min(0.95, abs(duration - expected) / expected)
            }
        elif duration > max_dur:
            return {
                "has_error": True,
                "rule_type": "MADD",
                "word": word,
                "position": position,
                "error_message_en": f"Madd too long ({duration:.2f}s, should be {expected:.2f}s)",
                "error_message_ur": f"مد بہت لمبی ہے - {duration:.2f} سیکنڈ، {expected:.2f} ہونی چاہیے",
                "measured_value": round(duration, 2),
                "expected_value": round(expected, 2),
                "confidence": min(0.95, abs(duration - expected) / expected)
            }
        
        return None  # No error
    
    def check_qalqalah(
        self,
        audio_segment: np.ndarray,
        letter: str,
        word: str,
        position: int
    ) -> Optional[Dict]:
        """
        Check for Qalqalah (echoing/bouncing sound)
        
        Qalqalah letters: ق ط ب ج د
        Should have sharp intensity spike (bounce effect)
        
        Args:
            audio_segment: Audio numpy array
            letter: Qalqalah letter
            word: Arabic word
            position: Position in ayah
        
        Returns:
            Dictionary with error details or None if correct
        """
        try:
            # Use LibROSA for intensity analysis (replaces Praat)
            # Calculate RMS energy as proxy for intensity
            rms = librosa.feature.rms(y=audio_segment, frame_length=2048, hop_length=512)[0]
            
            # Calculate spike
            max_intensity = np.max(rms)
            avg_intensity = np.mean(rms)
            
            if avg_intensity > 0:
                spike_ratio = (max_intensity - avg_intensity) / avg_intensity
            else:
                spike_ratio = 0
            
            threshold = self.thresholds['qalqalah']['intensity_spike_threshold']
            
            # Check for bounce
            if spike_ratio < threshold:
                return {
                    "has_error": True,
                    "rule_type": "QALQALAH",
                    "word": word,
                    "position": position,
                    "error_message_en": f"Missing Qalqalah bounce on letter '{letter}'",
                    "error_message_ur": f"حرف '{letter}' پر قلقلہ کی آواز نہیں ہے",
                    "measured_value": round(spike_ratio, 2),
                    "expected_value": threshold,
                    "confidence": 0.80
                }
        
        except Exception as e:
            print(f"⚠️  Qalqalah check error: {e}")
            return None
        
        return None  # No error
    
    def check_ghunnah(
        self,
        audio_segment: np.ndarray,
        letter: str,
        word: str,
        position: int
    ) -> Optional[Dict]:
        """
        Check Ghunnah (nasal sound)
        
        Ghunnah letters: ن م (with specific conditions)
        Should have:
        1. Nasal frequency content (250-500 Hz)
        2. Duration of ~2 harakaat (0.5s)
        
        Args:
            audio_segment: Audio numpy array
            letter: Ghunnah letter
            word: Arabic word
            position: Position in ayah
        
        Returns:
            Dictionary with error details or None if correct
        """
        # Check duration
        duration = len(audio_segment) / self.sample_rate
        min_dur, max_dur = self.thresholds['ghunnah']['duration']
        
        # Extract nasal frequencies using bandpass filter
        nyquist = self.sample_rate / 2
        low_freq = 250 / nyquist
        high_freq = 500 / nyquist
        
        try:
            b, a = signal.butter(4, [low_freq, high_freq], btype='band')
            nasal_filtered = signal.filtfilt(b, a, audio_segment)
            
            # Calculate nasal energy ratio
            nasal_energy = np.sum(nasal_filtered ** 2)
            total_energy = np.sum(audio_segment ** 2)
            
            if total_energy > 0:
                nasal_ratio = nasal_energy / total_energy
            else:
                nasal_ratio = 0
            
            threshold = self.thresholds['ghunnah']['nasal_threshold']
            
            # Check nasal quality
            if nasal_ratio < threshold:
                return {
                    "has_error": True,
                    "rule_type": "GHUNNAH",
                    "word": word,
                    "position": position,
                    "error_message_en": f"Ghunnah not nasal enough (nasal quality: {nasal_ratio:.0%})",
                    "error_message_ur": f"غنہ میں ناک سے آواز کم ہے - {nasal_ratio:.0%}",
                    "measured_value": round(nasal_ratio, 2),
                    "expected_value": threshold,
                    "confidence": 0.75
                }
            
            # Check duration
            if duration < min_dur or duration > max_dur:
                expected = (min_dur + max_dur) / 2
                return {
                    "has_error": True,
                    "rule_type": "GHUNNAH",
                    "word": word,
                    "position": position,
                    "error_message_en": f"Ghunnah duration incorrect ({duration:.2f}s, should be ~{expected:.2f}s)",
                    "error_message_ur": f"غنہ کی لمبائی غلط ہے - {duration:.2f} سیکنڈ، {expected:.2f} ہونی چاہیے",
                    "measured_value": round(duration, 2),
                    "expected_value": round(expected, 2),
                    "confidence": 0.75
                }
        
        except Exception as e:
            print(f"⚠️  Ghunnah check error: {e}")
            return None
        
        return None  # No error
    
    def extract_word_segment(
        self,
        full_audio: np.ndarray,
        word_start_time: float,
        word_end_time: float
    ) -> np.ndarray:
        """
        Extract audio segment for a specific word
        
        Args:
            full_audio: Complete audio array
            word_start_time: Start time in seconds
            word_end_time: End time in seconds
        
        Returns:
            Audio segment as numpy array
        """
        start_sample = int(word_start_time * self.sample_rate)
        end_sample = int(word_end_time * self.sample_rate)
        
        # Ensure indices are within bounds
        start_sample = max(0, start_sample)
        end_sample = min(len(full_audio), end_sample)
        
        return full_audio[start_sample:end_sample]
    
    def check_all_rules(
        self,
        audio_path: str,
        tajweed_rules: List[Dict],
        word_timings: List[Dict]
    ) -> Tuple[List[TajweedError], float]:
        """
        Check all Tajweed rules for an ayah
        
        Args:
            audio_path: Path to user's recitation
            tajweed_rules: List of expected Tajweed rules
            word_timings: Word-level timestamps
        
        Returns:
            Tuple of (errors_list, overall_accuracy)
        """
        # Load audio
        audio, sr = librosa.load(audio_path, sr=self.sample_rate)
        
        errors = []
        total_rules = len(tajweed_rules)
        
        if total_rules == 0:
            return [], 100.0
        
        for rule in tajweed_rules:
            # Find corresponding word timing
            word_timing = next(
                (w for w in word_timings if w['position'] == rule.get('position', -1)),
                None
            )
            
            if not word_timing:
                continue
            
            # Extract audio segment
            audio_segment = self.extract_word_segment(
                audio,
                word_timing['start_time'],
                word_timing['end_time']
            )
            
            if len(audio_segment) == 0:
                continue
            
            # Check based on rule type
            result = None
            
            if rule['type'] == 'MADD':
                result = self.check_madd(
                    audio_segment,
                    rule.get('madd_type', 'madd_asli'),
                    rule['word'],
                    rule['position']
                )
            
            elif rule['type'] == 'QALQALAH':
                result = self.check_qalqalah(
                    audio_segment,
                    rule['letter'],
                    rule['word'],
                    rule['position']
                )
            
            elif rule['type'] == 'GHUNNAH':
                result = self.check_ghunnah(
                    audio_segment,
                    rule['letter'],
                    rule['word'],
                    rule['position']
                )
            
            # Add to errors if found
            if result and result.get('has_error'):
                errors.append(TajweedError(**result))
        
        # Calculate accuracy
        accuracy = ((total_rules - len(errors)) / total_rules * 100) if total_rules > 0 else 100.0
        
        return errors, round(accuracy, 2)


# Global and singleton instance 
_tajweed_checker = None


def get_tajweed_checker() -> TajweedChecker:
    """
    Get or create tajweed checker instance
    (Dependency injection for FastAPI)
    """
    global _tajweed_checker
    if _tajweed_checker is None:
        _tajweed_checker = TajweedChecker()
    return _tajweed_checker
