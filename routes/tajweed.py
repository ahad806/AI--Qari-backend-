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

# Load data and its rules already written in the data folder
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
            # Step 1: Transcribe (now returns real word-level timestamps)
            print(f"📝 Transcribing audio for Surah {surah}, Ayah {ayah}...")
            transcription, confidence, word_timings = transcription_service.transcribe_audio(temp_path)
            
            # Get reference
            if not QURAN_DATA.get('surahs'):
                raise HTTPException(
                    status_code=503,
                    detail="Quran data not loaded"
                )
            
            # Lookup by .number field — NOT by array index
            surah_data = next(
                (s for s in QURAN_DATA['surahs'] if s.get('number') == surah),
                None
            )
            if surah_data is None:
                raise HTTPException(
                    status_code=404,
                    detail=f"Surah {surah} not found in data"
                )
            
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
            
            # Step 3: Word-level timing (real timestamps from Whisper)
            print(f"⏱️  Using {len(word_timings)} real word timestamps from Whisper...")
            # If Whisper returned no word timings (very short audio), fall back gracefully
            if not word_timings:
                print(f"⚠️  No word timestamps from Whisper, using equal-split fallback")
                audio_fb, sr_fb = librosa.load(temp_path, sr=16000)
                total_dur = len(audio_fb) / sr_fb
                ref_words = reference_text.split()
                word_dur = total_dur / max(len(ref_words), 1)
                word_timings = [
                    {"position": i, "word": w,
                     "start_time": round(i * word_dur, 3),
                     "end_time": round((i + 1) * word_dur, 3)}
                    for i, w in enumerate(ref_words)
                ]
            
            # Step 4: Guard — skip acoustic checks if wrong ayah recited
            # If the user uploaded the wrong Surah or full Surah audio,
            # Whisper word positions will be misaligned → false results.
            MATCH_THRESHOLD = 40.0
            match_pct       = comparison['similarity']
            wrong_ayah      = match_pct < MATCH_THRESHOLD

            if wrong_ayah:
                print(f"⚠️  Match too low ({match_pct}%) — skipping acoustic checks")
                errors         = []
                tajweed_accuracy = 0.0
                feedback_ur    = (f"غلط آیت تلاوت کی گئی ({match_pct:.0f}% مطابقت)۔ "
                                  f"براہ کرم سورۃ {surah} آیت {ayah} دوبارہ تلاوت کریں")
                feedback_en    = (f"Wrong ayah detected ({match_pct:.0f}% match). "
                                  f"Please recite Surah {surah} Ayah {ayah} again.")
            else:
                # Step 5: Run acoustic Tajweed checks
                print(f"🔍 Checking {len(tajweed_rules)} Tajweed rules "
                      f"(match={match_pct}%)...")
                errors, tajweed_accuracy = tajweed_service.check_all_rules(
                    temp_path, tajweed_rules, word_timings
                )

                if len(errors) == 0:
                    feedback_ur = "ماشاءاللہ! تجوید بالکل صحیح ہے"
                    feedback_en = "MashaAllah! All Tajweed rules are correct."
                else:
                    error_types = list(set(e.rule_type for e in errors))
                    feedback_ur = f"{len(errors)} غلطیاں ملیں: " + "، ".join(error_types)
                    feedback_en = (f"Found {len(errors)} error(s) in: "
                                   + ", ".join(error_types))

            print(f"Tajweed check complete. Accuracy: {tajweed_accuracy}%")

            return TajweedCheckResponse(
                success=True,
                overall_accuracy=tajweed_accuracy,
                transcription_match=match_pct,
                errors=errors,
                total_errors=len(errors),
                feedback_summary_ur=feedback_ur,
                feedback_summary_en=feedback_en
            )
            
        finally:
            # Fix #3: Windows holds a file lock briefly after pydub/Whisper
            # closes it. Swallow PermissionError — OS cleans Temp on reboot.
            if os.path.exists(temp_path):
                try:
                    os.unlink(temp_path)
                except PermissionError:
                    print(f"⚠️  Could not delete temp file (Windows lock): {temp_path}")
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Tajweed check error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Tajweed check failed: {str(e)}"
        )

