"""
Speech transcription service using Faster-Whisper (Quran-specific model)
"""

from faster_whisper import WhisperModel
import torch
import librosa
import numpy as np
from typing import Tuple, Dict
from config import WHISPER_MODEL, SAMPLE_RATE
from pydub import AudioSegment
import tempfile
import os


class TranscriptionService:
    """
    Faster-Whisper-based Arabic Quranic speech transcription service
    Uses model fine-tuned specifically on Quranic recitation
    """
    
    def __init__(self):
        """
        Initialize Faster-Whisper model for Quranic transcription
        """
        print(f"📥 Loading Faster-Whisper model: {WHISPER_MODEL}")
        
        # Determine device (GPU if available, otherwise CPU)
        device = "cuda" if torch.cuda.is_available() else "cpu"
        compute_type = "float16" if device == "cuda" else "int8"
        
        # Load the Faster-Whisper model
        self.model = WhisperModel(
            WHISPER_MODEL,
            device=device,
            compute_type=compute_type
        )
        
        self.device = device
        print(f"✅ Faster-Whisper model loaded successfully on {device}")
    
    def transcribe_audio(self, audio_path: str) -> Tuple[str, float]:
        """
        Transcribe audio file to Arabic text using Faster-Whisper
        
        Args:
            audio_path: Path to audio file (.wav, .mp3, .m4a)
        
        Returns:
            Tuple of (transcription, confidence_score)
        """
        try:
            # Convert audio to WAV format with 16kHz sample rate if needed
            temp_wav_path = None
            
            if not audio_path.endswith('.wav'):
                # Convert to WAV using pydub
                audio = AudioSegment.from_file(audio_path)
                audio = audio.set_frame_rate(SAMPLE_RATE)
                audio = audio.set_channels(1)  # Mono
                
                # Create temporary WAV file
                temp_wav_path = tempfile.mktemp(suffix='.wav')
                audio.export(temp_wav_path, format="wav")
                process_path = temp_wav_path
            else:
                # Ensure 16kHz sample rate for WAV files
                audio, sr = librosa.load(audio_path, sr=SAMPLE_RATE)
                temp_wav_path = tempfile.mktemp(suffix='.wav')
                import soundfile as sf
                sf.write(temp_wav_path, audio, SAMPLE_RATE)
                process_path = temp_wav_path
            
            # Transcribe using Faster-Whisper
            segments, info = self.model.transcribe(
                process_path,
                language="ar",  # Arabic language
                beam_size=5,    # Better accuracy
                vad_filter=True,  # Voice Activity Detection
                vad_parameters=dict(min_silence_duration_ms=500)
            )
            
            # Collect transcription and calculate average confidence
            transcription_parts = []
            confidences = []
            
            for segment in segments:
                transcription_parts.append(segment.text)
                confidences.append(segment.avg_logprob)  # Log probability
            
            # Combine transcription
            transcription = " ".join(transcription_parts).strip()
            
            # Calculate confidence (convert log prob to probability)
            if confidences:
                avg_confidence = np.exp(np.mean(confidences))  # Convert log prob to prob
                # Normalize to 0-1 range
                confidence = min(max(avg_confidence, 0.0), 1.0)
            else:
                confidence = 0.0
            
            # Clean up temporary file
            if temp_wav_path and os.path.exists(temp_wav_path):
                os.remove(temp_wav_path)
            
            print(f"✅ Transcription successful: {transcription[:50]}...")
            print(f"📊 Confidence: {confidence:.2%}")
            
            return transcription, confidence
            
        except Exception as e:
            print(f"❌ Transcription error: {e}")
            # Clean up on error
            if temp_wav_path and os.path.exists(temp_wav_path):
                os.remove(temp_wav_path)
            raise
    
    def compare_texts(self, user_text: str, reference_text: str) -> Dict:
        """
        Compare user transcription with reference
        
        Args:
            user_text: User's transcribed text
            reference_text: Correct reference text
        
        Returns:
            Dictionary with match percentage and word-level comparison
        """
        from difflib import SequenceMatcher
        
        # Normalize texts (remove extra spaces)
        user_text = ' '.join(user_text.strip().split())
        reference_text = ' '.join(reference_text.strip().split())
        
        # Split into words
        user_words = user_text.split()
        ref_words = reference_text.split()
        
        # Calculate similarity
        matcher = SequenceMatcher(None, user_words, ref_words)
        similarity = matcher.ratio() * 100
        
        # Word-level comparison
        word_comparison = []
        max_len = max(len(user_words), len(ref_words))
        
        for i in range(max_len):
            user_word = user_words[i] if i < len(user_words) else ""
            ref_word = ref_words[i] if i < len(ref_words) else ""
            
            word_comparison.append({
                "position": i,
                "user": user_word,
                "reference": ref_word,
                "match": user_word == ref_word
            })
        
        correct_words = sum(1 for w in word_comparison if w['match'])
        
        return {
            "similarity": round(similarity, 2),
            "word_comparison": word_comparison,
            "total_words": len(ref_words),
            "correct_words": correct_words
        }


# Global instance (singleton pattern)
_transcription_service = None


def get_transcription_service() -> TranscriptionService:
    """
    Get or create transcription service instance
    (Dependency injection for FastAPI)
    """
    global _transcription_service
    if _transcription_service is None:
        _transcription_service = TranscriptionService()
    return _transcription_service
