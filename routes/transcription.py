"""
Transcription endpoints
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Form
from models.schemas import TranscriptionResponse, WordComparison
from services.transcription import get_transcription_service, TranscriptionService
import os
import tempfile
import json
from pathlib import Path as FilePath

router = APIRouter()

# Load Quran data
DATA_DIR = FilePath(__file__).parent.parent / "data"

try:
    with open(DATA_DIR / 'quran_text.json', 'r', encoding='utf-8') as f:
        QURAN_DATA = json.load(f)
except FileNotFoundError:
    QURAN_DATA = {"surahs": []}


@router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    summary="Transcribe Quranic Recitation",
    description="Upload audio file and get Arabic transcription with accuracy"
)
async def transcribe(
    audio: UploadFile = File(..., description="Audio file (.wav, .mp3, .m4a)"),
    surah: int = Form(..., description="Surah number (1-114)"),
    ayah: int = Form(..., description="Ayah number"),
    service: TranscriptionService = Depends(get_transcription_service)
):
    """
    Transcribe user's recitation to Arabic text
    
    **Parameters:**
    - **audio**: Audio file (WAV or MP3, 16kHz recommended)
    - **surah**: Surah number (1-114)
    - **ayah**: Ayah number
    
    **Returns:**
    - Transcribed Arabic text
    - Confidence score
    - Match percentage with reference
    - Word-by-word comparison
    
    **Example using curl:**
    ```bash
    curl -X POST "http://localhost:8000/api/transcribe" \
      -F "audio=@recitation.wav" \
      -F "surah=1" \
      -F "ayah=1"
    ```
    
    **Example using Python:**
    ```python
    import requests
    
    files = {'audio': open('recitation.wav', 'rb')}
    data = {'surah': 1, 'ayah': 1}
    
    response = requests.post(
        'http://localhost:8000/api/transcribe',
        files=files,
        data=data
    )
    print(response.json())
    ```
    """
    try:
        # Validate file type
        if not audio.filename.endswith(('.wav', '.mp3', '.m4a')):
            raise HTTPException(
                status_code=400,
                detail="Only .wav, .mp3, or .m4a files are supported"
            )
        
        # Check file size (max 10MB)
        content = await audio.read()
        if len(content) > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=400,
                detail="Audio file too large. Maximum size is 10MB"
            )
        
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            temp_file.write(content)
            temp_path = temp_file.name
        
        try:
            # Transcribe
            transcription, confidence = service.transcribe_audio(temp_path)
            
            # Get reference text
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
            
            # Compare with reference
            comparison = service.compare_texts(transcription, reference_text)
            
            # Convert word comparison to Pydantic models
            word_comp = [
                WordComparison(**w) for w in comparison['word_comparison']
            ]
            
            return TranscriptionResponse(
                success=True,
                transcription=transcription,
                confidence=round(confidence, 2),
                arabic_text=reference_text,
                match_percentage=comparison['similarity'],
                word_comparison=word_comp
            )
            
        finally:
            # Clean up temp file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {str(e)}"
        )
