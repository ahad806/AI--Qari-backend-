"""
Reference data endpoints
"""

from fastapi import APIRouter, HTTPException, Path
from models.schemas import AyahReference, TajweedRule, SurahInfo, SurahListResponse
import json
from pathlib import Path as FilePath
from typing import List

router = APIRouter()

# Load data files
DATA_DIR = FilePath(__file__).parent.parent / "data"

try:
    with open(DATA_DIR / 'quran_text.json', 'r', encoding='utf-8') as f:
        QURAN_DATA = json.load(f)
except FileNotFoundError:
    print("⚠️  Warning: quran_text.json not found. Creating sample data...")
    QURAN_DATA = {"surahs": []}

try:
    with open(DATA_DIR / 'tajweed_rules.json', 'r', encoding='utf-8') as f:
        TAJWEED_RULES = json.load(f)
except FileNotFoundError:
    print("⚠️  Warning: tajweed_rules.json not found. Creating sample data...")
    TAJWEED_RULES = {}


@router.get(
    "/reference/{surah_number}/{ayah_number}",
    response_model=AyahReference,
    summary="Get Ayah Reference Data",
    description="Returns Arabic text, translations, and Tajweed rules for a specific ayah"
)
async def get_reference(
    surah_number: int = Path(..., ge=1, le=114, description="Surah number (1-114)"),
    ayah_number: int = Path(..., ge=1, description="Ayah number")
):
    """
    Get reference data for an ayah
    
    **Example:**
    ```
    GET /api/reference/1/1
    ```
    
    **Returns:**
    - Arabic text from Tanzil.net
    - English and Urdu translations
    - Tajweed rules with positions
    - Audio URL
    """
    try:
        # Validate data exists
        if not QURAN_DATA.get('surahs'):
            raise HTTPException(
                status_code=503,
                detail="Quran data not loaded. Please add quran_text.json to data folder."
            )
        
        # Lookup by .number field — NOT by array index
        surah_data = next(
            (s for s in QURAN_DATA['surahs'] if s.get('number') == surah_number),
            None
        )
        if surah_data is None:
            raise HTTPException(
                status_code=404,
                detail=f"Surah {surah_number} not found in data"
            )
        
        # Validate ayah number
        if ayah_number > len(surah_data['ayahs']):
            raise HTTPException(
                status_code=404,
                detail=f"Ayah {ayah_number} not found in Surah {surah_number}"
            )
        
        ayah_data = surah_data['ayahs'][ayah_number - 1]
        
        # Get Tajweed rules
        rules_key = f"{surah_number}:{ayah_number}"
        rules_data = TAJWEED_RULES.get(rules_key, [])
        
        # Convert to TajweedRule objects
        tajweed_rules = [
            TajweedRule(**rule) for rule in rules_data
        ]
        
        return AyahReference(
            surah=surah_data['name'],
            surah_number=surah_number,
            ayah=ayah_number,
            arabic_text=ayah_data['text'],
            translation_en=ayah_data.get('translation_en', ''),
            translation_ur=ayah_data.get('translation_ur', ''),
            tajweed_rules=tajweed_rules,
            audio_url=f"https://cdn.islamic.network/quran/audio/128/ar.alafasy/{surah_number}_{ayah_number}.mp3"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")


@router.get(
    "/surahs",
    response_model=SurahListResponse,
    summary="Get List of All Surahs",
    description="Returns list of all 114 Surahs with metadata"
)
async def get_surahs():
    """
    Get list of all Surahs
    
    **Returns:**
    - Surah number, name (Arabic & English)
    - Number of ayahs
    - Revelation place (Makkah/Madinah)
    """
    try:
        if not QURAN_DATA.get('surahs'):
            raise HTTPException(
                status_code=503,
                detail="Quran data not loaded"
            )
        
        surahs = []
        for surah in QURAN_DATA['surahs']:
            surahs.append(SurahInfo(
                number=surah['number'],             # ← actual surah number (e.g. 112, 113)
                name_arabic=surah['name'],
                name_english=surah.get('name_english', ''),
                total_ayahs=len(surah['ayahs']),
                revelation=surah.get('revelation', 'Makkah')
            ))
        
        return SurahListResponse(success=True, data=surahs)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
