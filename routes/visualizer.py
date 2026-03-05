"""
Tajweed Visualizer endpoint
Returns word-by-word color-coded Tajweed annotation for an ayah.
No audio upload required — pure data, instant response.
"""

from fastapi import APIRouter, HTTPException, Path, UploadFile, File, Form, Depends
from models.schemas import (
    VisualizerResponse, WordAnnotation, WordRuleAnnotation,
    EvaluatedWordAnnotation, TajweedEvaluationResponse
)
from services.transcription import TranscriptionService, get_transcription_service
from services.tajweed_checker import TajweedChecker, get_tajweed_checker
from models.schemas import TajweedError as TajweedErrorModel
import json
import tempfile
import os
import io
from pathlib import Path as FilePath
from typing import List, Dict

router = APIRouter()

# ─── Load data once at module startup ────────────────────────────────────────

DATA_DIR = FilePath(__file__).parent.parent / "data"

try:
    with open(DATA_DIR / "quran_text.json", "r", encoding="utf-8") as f:
        QURAN_DATA = json.load(f)
except FileNotFoundError:
    QURAN_DATA = {"surahs": []}

try:
    with open(DATA_DIR / "tajweed_rules.json", "r", encoding="utf-8") as f:
        TAJWEED_RULES = json.load(f)
except FileNotFoundError:
    TAJWEED_RULES = {}


# ─── Color palette per rule type ─────────────────────────────────────────────

RULE_COLORS = {
    "MADD":      "#3b82f6",   # Blue  — elongation
    "QALQALAH":  "#f97316",   # Orange — bouncing/echoing
    "GHUNNAH":   "#22c55e",   # Green  — nasal sound
}

NEUTRAL_COLOR = "#94a3b8"     # Slate — word with no rule


# ─── Short labels per rule type and sub-type ─────────────────────────────────

MADD_LABELS = {
    "madd_asli":   {"en": "Madd Asli (2 harakaat)",  "ur": "مد اصلی - 2 حرکت"},
    "madd_wajib":  {"en": "Madd Wajib (4-5 harakaat)", "ur": "مد واجب - 5 حرکت"},
    "madd_lazim":  {"en": "Madd Lazim (6 harakaat)",  "ur": "مد لازم - 6 حرکت"},
}

RULE_LABELS = {
    "QALQALAH": {"en": "Qalqalah (bounce/echo)", "ur": "قلقلہ"},
    "GHUNNAH":  {"en": "Ghunnah (nasal sound)",  "ur": "غنہ - 2 حرکت"},
}


# ─── Helper: build a WordRuleAnnotation from a raw rule dict ─────────────────

def build_rule_annotation(rule: Dict) -> WordRuleAnnotation:
    rule_type = rule["type"]
    color = RULE_COLORS.get(rule_type, NEUTRAL_COLOR)

    if rule_type == "MADD":
        madd_type = rule.get("madd_type", "madd_asli")
        labels = MADD_LABELS.get(madd_type, MADD_LABELS["madd_asli"])
        label_en = labels["en"]
        label_ur = labels["ur"]
    else:
        labels = RULE_LABELS.get(rule_type, {"en": rule_type, "ur": rule_type})
        label_en = labels["en"]
        label_ur = labels["ur"]

    return WordRuleAnnotation(
        type=rule_type,
        letter=rule.get("letter", ""),
        color=color,
        label_en=label_en,
        label_ur=label_ur,
        description_en=rule.get("description_en", ""),
        description_ur=rule.get("description_ur", ""),
        madd_type=rule.get("madd_type"),
        duration_expected=rule.get("duration_expected"),
    )


# ─── Helper: build WordAnnotation list for all words in an ayah ──────────────

def build_word_annotations(arabic_text: str, rules: List[Dict]) -> List[WordAnnotation]:
    """
    Split the ayah text into words, map each rule to its word by position,
    and return a WordAnnotation per word.
    """
    words = arabic_text.split()

    # Build a dict: position → list of rules
    rules_by_position: Dict[int, List[Dict]] = {}
    for rule in rules:
        pos = rule.get("position", -1)
        if pos >= 0:
            rules_by_position.setdefault(pos, []).append(rule)

    annotations = []
    for idx, word_text in enumerate(words):
        word_rules_raw = rules_by_position.get(idx, [])
        word_rule_annotations = [build_rule_annotation(r) for r in word_rules_raw]

        # Dominant color: use the first rule's color, or neutral if no rules
        if word_rule_annotations:
            primary_color = word_rule_annotations[0].color
        else:
            primary_color = NEUTRAL_COLOR

        annotations.append(WordAnnotation(
            position=idx,
            word=word_text,
            rules=word_rule_annotations,
            primary_color=primary_color,
            has_rule=len(word_rule_annotations) > 0,
        ))

    return annotations


# ─── Endpoint ─────────────────────────────────────────────────────────────────

@router.get(
    "/tajweed-highlight/{surah_number}/{ayah_number}",
    response_model=VisualizerResponse,
    summary="Get Tajweed Visual Highlights",
    description=(
        "Returns word-by-word Tajweed color annotations for an ayah. "
        "No audio required — instant response from static data. "
        "Use these colors to highlight words in your frontend: "
        "🔵 Blue = Madd, 🟠 Orange = Qalqalah, 🟢 Green = Ghunnah."
    )
)
async def get_tajweed_highlight(
    surah_number: int = Path(..., ge=1, le=114, description="Surah number (1-114)"),
    ayah_number: int  = Path(..., ge=1,         description="Ayah number"),
):
    """
    Tajweed Visualizer — returns color-coded word annotations.

    **Color coding:**
    - 🔵 `#3b82f6` Blue  → Madd (vowel elongation)
    - 🟠 `#f97316` Orange → Qalqalah (bouncing/echoing sound)
    - 🟢 `#22c55e` Green  → Ghunnah (nasal sound)
    - ⚪ `#94a3b8` Slate  → No Tajweed rule on this word

    **Example:**
    ```
    GET /api/tajweed-highlight/1/1
    GET /api/tajweed-highlight/112/3
    GET /api/tajweed-highlight/113/4
    ```
    """
    try:
        # ── 1. Validate data is loaded ────────────────────────────────────────
        if not QURAN_DATA.get("surahs"):
            raise HTTPException(status_code=503, detail="Quran data not loaded")

        # ── 2. Find surah by .number field (not array index) ──────────────────
        surah_data = next(
            (s for s in QURAN_DATA["surahs"] if s.get("number") == surah_number),
            None
        )
        if surah_data is None:
            raise HTTPException(
                status_code=404,
                detail=f"Surah {surah_number} not found in data"
            )

        # ── 3. Validate ayah number ───────────────────────────────────────────
        if ayah_number > len(surah_data["ayahs"]):
            raise HTTPException(
                status_code=404,
                detail=f"Ayah {ayah_number} not found in Surah {surah_number}"
            )

        ayah_data = surah_data["ayahs"][ayah_number - 1]
        arabic_text = ayah_data["text"]

        # ── 4. Get Tajweed rules for this ayah ────────────────────────────────
        rules_key = f"{surah_number}:{ayah_number}"
        raw_rules = TAJWEED_RULES.get(rules_key, [])

        # ── 5. Build word-level annotations ───────────────────────────────────
        word_annotations = build_word_annotations(arabic_text, raw_rules)

        total_rules = sum(len(wa.rules) for wa in word_annotations)

        # ── 6. Build audio URL (islamic.network CDN) ──────────────────────────
        audio_url = (
            f"https://cdn.islamic.network/quran/audio/128/ar.alafasy/"
            f"{surah_number}_{ayah_number}.mp3"
        )

        print(
            f"✅ Visualizer: Surah {surah_number} Ayah {ayah_number} — "
            f"{len(word_annotations)} words, {total_rules} rules"
        )

        return VisualizerResponse(
            success=True,
            surah_number=surah_number,
            surah_name=surah_data["name"],
            ayah_number=ayah_number,
            arabic_text=arabic_text,
            translation_en=ayah_data.get("translation_en", ""),
            translation_ur=ayah_data.get("translation_ur", ""),
            word_annotations=word_annotations,
            total_rules=total_rules,
            audio_url=audio_url,
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Visualizer error: {e}")
        raise HTTPException(status_code=500, detail=f"Visualizer failed: {str(e)}")


# ─── Phase 2: Evaluation Colors ───────────────────────────────────────────────

STATUS_COLORS = {
    "correct":     "#22c55e",   # Green  — rule applied correctly
    "error":       "#ef4444",   # Red    — rule violated
    "no_rule":     "#94a3b8",   # Slate  — no Tajweed rule on this word
    "not_checked": "#facc15",   # Yellow — rule exists but couldn't verify (no timing)
}


# ─── Phase 2: Endpoint ────────────────────────────────────────────────────────

@router.post(
    "/check-tajweed-with-highlights",
    response_model=TajweedEvaluationResponse,
    summary="Real-Time Tajweed Correction + Visual Highlights",
    description=(
        "Upload a recitation audio file. Returns word-by-word color-coded feedback: "
        "🟢 Green = correct Tajweed, 🔴 Red = error with explanation, ⚪ Slate = no rule. "
        "Also returns overall accuracy score and full transcription."
    )
)
async def check_tajweed_with_highlights(
    audio:  UploadFile = File(...,  description="Audio file (.wav/.mp3/.m4a)"),
    surah:  int        = Form(...,  ge=1, le=114, description="Surah number"),
    ayah:   int        = Form(...,  ge=1,         description="Ayah number"),
    transcription_service: TranscriptionService = Depends(get_transcription_service),
    tajweed_service:       TajweedChecker       = Depends(get_tajweed_checker),
):
    """
    Phase 2 — Combined Tajweed Correction + Visualizer.

    **Flow:**
    1. Transcribe audio with Whisper (real word timestamps)
    2. Compare transcription to reference text
    3. Run acoustic Tajweed checks on each word's audio segment
    4. Merge results into color-coded word annotations
    5. Return everything in one response

    **Color coding (evaluated):**
    - 🟢 `#22c55e` → Rule applied correctly
    - 🔴 `#ef4444` → Rule violated (with specific error message)
    - 🟡 `#facc15` → Rule exists but timing not available to verify
    - ⚪ `#94a3b8` → No Tajweed rule on this word
    """
    temp_path = None
    try:
        # ── 1. Save uploaded audio to temp file ───────────────────────────────
        content = await audio.read()
        original_suffix = os.path.splitext(audio.filename or "")[1].lower()

        # Always write a .wav to disk so the transcription service
        # never needs ffprobe (which may not be on PATH in every shell).
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            if original_suffix in (".mp3", ".m4a", ".ogg", ".flac"):
                # Convert to WAV in-memory first, then write
                from pydub import AudioSegment as _AS
                audio_seg = _AS.from_file(
                    io.BytesIO(content),
                    format=original_suffix.lstrip(".")
                )
                audio_seg = audio_seg.set_frame_rate(16000).set_channels(1)
                audio_seg.export(tmp, format="wav")
            else:
                # Already .wav — write bytes directly
                tmp.write(content)
            temp_path = tmp.name

        # ── 2. Validate Quran data ─────────────────────────────────────────────
        if not QURAN_DATA.get("surahs"):
            raise HTTPException(status_code=503, detail="Quran data not loaded")

        surah_data = next(
            (s for s in QURAN_DATA["surahs"] if s.get("number") == surah),
            None
        )
        if surah_data is None:
            raise HTTPException(status_code=404, detail=f"Surah {surah} not found")

        if ayah > len(surah_data["ayahs"]):
            raise HTTPException(status_code=404, detail=f"Ayah {ayah} not found in Surah {surah}")

        ayah_data    = surah_data["ayahs"][ayah - 1]
        arabic_text  = ayah_data["text"]
        rules_key    = f"{surah}:{ayah}"

        #getting relevent rules from here
        raw_rules    = TAJWEED_RULES.get(rules_key, [])

        audio_url = (
            f"https://cdn.islamic.network/quran/audio/128/ar.alafasy/"
            f"{surah}_{ayah}.mp3"
        )

        # ── 3. Transcribe with real word timestamps ────────────────────────────
        print(f"📝 Transcribing for Surah {surah} Ayah {ayah}...")
        transcription, confidence, word_timings = transcription_service.transcribe_audio(temp_path)

        # ── 4. Compare transcription to reference ──────────────────────────────
        comparison       = transcription_service.compare_texts(transcription, arabic_text)
        match_percentage = round(comparison.get("similarity", 0.0), 2)

        
        print(f"🔍 Checking {len(raw_rules)} Tajweed rules (match={match_percentage}%)...")
        errors_list, accuracy = tajweed_service.check_all_rules(
            temp_path, raw_rules, word_timings
        )

        
        errors_by_position: Dict[int, TajweedErrorModel] = {
            err.position: err for err in errors_list
        }

        # ── 6. Build word-level rule annotations ──────────────────────────────
        words = arabic_text.split()
        rules_by_position: Dict[int, List[Dict]] = {}
        for rule in raw_rules:
            pos = rule.get("position", -1)
            if pos >= 0:
                rules_by_position.setdefault(pos, []).append(rule)

        # ── 7. Merge rules + check results into EvaluatedWordAnnotation ───────
        evaluated_words = []
        for idx, word_text in enumerate(words):
            word_rules_raw   = rules_by_position.get(idx, [])
            rule_annotations = [build_rule_annotation(r) for r in word_rules_raw]

           

            if not word_rules_raw:
                # No Tajweed rule for this word
                status      = "no_rule"
                feedback_en = "No specific Tajweed rule for this word"
                feedback_ur = "اس لفظ پر کوئی مخصوص تجوید کا قاعدہ نہیں"

            elif idx in errors_by_position:
                # Rule exists AND acoustic error detected
                err         = errors_by_position[idx]
                status      = "error"
                feedback_en = err.error_message_en
                feedback_ur = err.error_message_ur

            else:
                # Rule exists, no error → correct!
                rule_type   = word_rules_raw[0]["type"]
                status      = "correct"
                feedback_en = f"Correct! {rule_type.capitalize()} applied properly."
                feedback_ur = f"درست! {rule_type} صحیح ادا کیا۔"

            evaluated_words.append(EvaluatedWordAnnotation(
                position=idx,
                word=word_text,
                rules=rule_annotations,
                status=status,
                color=STATUS_COLORS[status],
                feedback_en=feedback_en,
                feedback_ur=feedback_ur,
            ))

        total_errors = len(errors_list)
        print(
            f"✅ Evaluation done: {len(evaluated_words)} words, "
            f"{total_errors} errors, accuracy={accuracy}%"
        )

        return TajweedEvaluationResponse(
            success=True,
            surah_number=surah,
            surah_name=surah_data["name"],
            ayah_number=ayah,
            arabic_text=arabic_text,
            transcription=transcription,
            transcription_match=match_percentage,
            overall_accuracy=accuracy,
            total_rules_checked=len(raw_rules),
            total_errors=total_errors,
            word_annotations=evaluated_words,
            audio_url=audio_url,
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Evaluation error: {e}")
        raise HTTPException(status_code=500, detail=f"Evaluation failed: {str(e)}")
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except PermissionError:
                # Windows holds file lock briefly after pydub/Whisper closes it
                # The OS will clean it from Temp automatically on next boot
                print(f"⚠️  Could not delete temp file (Windows lock): {temp_path}")
