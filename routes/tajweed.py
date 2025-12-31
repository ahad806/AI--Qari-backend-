"""
Tajweed checking endpoints
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Form
from models.schemas import TajweedCheckResponse, TajweedError
from services.tajweed_checker import get_tajweed_checker, TajweedChecker
from services.transcription import get_transcription_service, TranscriptionService
import os
import tempfile
import json
import librosa
from pathlib import Path as FilePath
from typing import List, Dict

router = APIRouter()

# Load data
DATA_DIR = FilePath(__file__).parent.parent / "data"

try:
    with open(DATA_DIR / 'quran_text.json', 'r', encoding='utf-8') as f:
        QURAN_DATA = json.load(f)
except FileNotFoundError:
    QURAN_DATA = {"surahs": []}

try:
    with open(DATA_DIR / 'tajweed_rules.json', 'r', encoding='utf-8') as f:
        TAJWEED_RULES = json.load(f)
except FileNotFoundError:
    TAJWEED_RULES = {}


@router.post(
    "/check-tajweed",
    response_model=TajweedCheckResponse,
    summary="Check Tajweed Rules",
    description="Analyze recitation for Tajweed errors (Madd, Qalqalah, Ghunnah)"
)
async def check_tajweed(
    audio: UploadFile = File(..., description="Audio file of recitation"),
    surah: int = Form(..., description="Surah number (1-114)"),
    ayah: int = Form(..., description="Ayah number"),
    tajweed_service: TajweedChecker = Depends(get_tajweed_checker),
    transcription_service: TranscriptionService = Depends(get_transcription_service)
):
    """
    Complete Tajweed analysis with detailed feedback
    
    **Process:**
    1. Transcribe audio to text
    2. Compare with reference text
    3. Check Madd, Qalqalah, Ghunnah rules
    4. Return detailed feedback in Urdu and English
    
    **Example using curl:**
    ```bash
    curl -X POST "http://localhost:8000/api/check-tajweed" \
      -F "audio=@my_recitation.wav" \
      -F "surah=1" \
      -F "ayah=1"
    ```
    
    **Example using Python:**
    ```python
    import requests
    
    files = {'audio': open('recitation.wav', 'rb')}
    data = {'surah': 1, 'ayah': 1}
    
    response = requests.post(
        'http://localhost:8000/api/check-tajweed',
        files=files,
        data=data
    )
    
    result = response.json()
    print(f"Accuracy: {result['overall_accuracy']}%")
    print(f"Errors: {result['total_errors']}")
    for error in result['errors']:
        print(f"- {error['error_message_en']}")
    ```
    
    **Returns:**
    - List of Tajweed errors with positions
    - Overall accuracy percentage
    - Transcription match percentage
    - Feedback summary in Urdu and English
    """
    try:
        # Validate file
        if not audio.filename.endswith(('.wav', '.mp3', '.m4a')):
            raise HTTPException(
                status_code=400,
                detail="Only .wav, .mp3, or .m4a files are supported"
            )
        
        # Check file size
        content = await audio.read()
        if len(content) > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=400,
                detail="Audio file too large. Maximum size is 10MB"
            )
        
        # Save uploaded file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            temp_file.write(content)
            temp_path = temp_file.name
        
        try:
            # Step 1: Transcribe
            print(f"📝 Transcribing audio for Surah {surah}, Ayah {ayah}...")
            transcription, confidence = transcription_service.transcribe_audio(temp_path)
            
            # Get reference
            if not QURAN_DATA.get('surahs'):
                raise HTTPException(
                    status_code=503,
                    detail="Quran data not loaded"
                )
            
            if surah > len(QURAN_DATA['surahs']):
                raise HTTPException(
                    status_code=404,
                    detail=f"Surah {surah} not found"
                )
            
            surah_data = QURAN_DATA['surahs'][surah - 1]
            
            if ayah > len(surah_data['ayahs']):
                raise HTTPException(
                    status_code=404,
                    detail=f"Ayah {ayah} not found in Surah {surah}"
                )
            
            ayah_data = surah_data['ayahs'][ayah - 1]
            reference_text = ayah_data['text']
            
            # Compare transcription
            comparison = transcription_service.compare_texts(transcription, reference_text)
            print(f"✅ Transcription match: {comparison['similarity']}%")
            
            # Step 2: Get Tajweed rules for this ayah
            rules_key = f"{surah}:{ayah}"
            tajweed_rules = TAJWEED_RULES.get(rules_key, [])
            
            if not tajweed_rules:
                print(f"⚠️  No Tajweed rules defined for {rules_key}")
                return TajweedCheckResponse(
                    success=True,
                    overall_accuracy=100.0,
                    transcription_match=comparison['similarity'],
                    errors=[],
                    total_errors=0,
                    feedback_summary_ur="اس آیت کے لیے تجوید کے اصول موجود نہیں",
                    feedback_summary_en="No Tajweed rules defined for this ayah"
                )
            
            # Step 3: Word-level timing (simplified for MVP)
            print(f"⏱️  Estimating word timings...")
            word_timings = estimate_word_timings(temp_path, reference_text.split())
            
            # Step 4: Check Tajweed rules
            print(f"🔍 Checking {len(tajweed_rules)} Tajweed rules...")
            errors, tajweed_accuracy = tajweed_service.check_all_rules(
                temp_path,
                tajweed_rules,
                word_timings
            )
            
            # Generate feedback summary
            if len(errors) == 0:
                feedback_ur = "ماشاءاللہ! تجوید بالکل صحیح ہے"
                feedback_en = "MashaAllah! All Tajweed rules are correct"
            else:
                error_types = list(set(e.rule_type for e in errors))
                feedback_ur = f"{len(errors)} غلطیاں ملیں: " + "، ".join(error_types)
                feedback_en = f"Found {len(errors)} error(s) in: " + ", ".join(error_types)
            
            print(f"✅ Tajweed check complete. Accuracy: {tajweed_accuracy}%")
            
            return TajweedCheckResponse(
                success=True,
                overall_accuracy=tajweed_accuracy,
                transcription_match=comparison['similarity'],
                errors=errors,
                total_errors=len(errors),
                feedback_summary_ur=feedback_ur,
                feedback_summary_en=feedback_en
            )
            
        finally:
            # Clean up temp file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Tajweed check error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Tajweed check failed: {str(e)}"
        )


def estimate_word_timings(audio_path: str, words: List[str]) -> List[Dict]:
    """
    Estimate word-level timestamps (simplified for MVP)
    
    For production: Use Montreal Forced Aligner or similar tools
    For MVP: Divide audio duration equally among words
    
    Args:
        audio_path: Path to audio file
        words: List of words
    
    Returns:
        List of dictionaries with word timings
    """
    # Load audio to get duration
    audio, sr = librosa.load(audio_path, sr=16000)
    total_duration = len(audio) / sr
    
    # Divide equally among words
    word_duration = total_duration / len(words) if len(words) > 0 else 0
    
    timings = []
    for i, word in enumerate(words):
        timings.append({
            "position": i,
            "word": word,
            "start_time": i * word_duration,
            "end_time": (i + 1) * word_duration
        })
    
    return timings
