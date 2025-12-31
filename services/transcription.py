"""
Speech transcription service using Wav2Vec2
"""

from transformers import Wav2Vec2Processor, Wav2Vec2ForCTC
import torch
import librosa
import numpy as np
from typing import Tuple, Dict
from config import WAV2VEC2_MODEL, SAMPLE_RATE


class TranscriptionService:
    """
    Wav2Vec2-based Arabic speech transcription service
    """
    
    def __init__(self):
        """
        Initialize Wav2Vec2 model for Arabic transcription
        """
        print(f"📥 Loading Wav2Vec2 model: {WAV2VEC2_MODEL}")
        
        self.processor = Wav2Vec2Processor.from_pretrained(WAV2VEC2_MODEL)
        self.model = Wav2Vec2ForCTC.from_pretrained(WAV2VEC2_MODEL)
        
        # Move to GPU if available
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model.to(self.device)
        
        print(f"✅ Model loaded successfully on {self.device}")
    
    def transcribe_audio(self, audio_path: str) -> Tuple[str, float]:
        """
        Transcribe audio file to Arabic text
        
        Args:
            audio_path: Path to audio file (.wav, .mp3)
        
        Returns:
            Tuple of (transcription, confidence_score)
        """
        try:
            # Load audio
            audio, sr = librosa.load(audio_path, sr=SAMPLE_RATE)
            
            # Process audio
            inputs = self.processor(
                audio,
                sampling_rate=SAMPLE_RATE,
                return_tensors="pt",
                padding=True
            )
            
            # Move to device
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            # Transcribe
            with torch.no_grad():
                logits = self.model(**inputs).logits
            
            # Decode
            predicted_ids = torch.argmax(logits, dim=-1)
            transcription = self.processor.batch_decode(predicted_ids)[0]
            
            # Calculate confidence (average of max probabilities)
            probabilities = torch.softmax(logits, dim=-1)
            max_probs = torch.max(probabilities, dim=-1)[0]
            confidence = max_probs.mean().item()
            
            return transcription, confidence
            
        except Exception as e:
            print(f"❌ Transcription error: {e}")
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
