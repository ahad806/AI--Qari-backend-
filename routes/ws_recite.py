"""
WebSocket endpoint for Real-Time Tajweed Correction (Phase 3)

Protocol:
  CLIENT → SERVER (text JSON):   {"type": "start", "surah": 1, "ayah": 1}
  CLIENT → SERVER (binary):       <raw audio bytes — WAV/PCM chunks>
  CLIENT → SERVER (text JSON):   {"type": "done"}

  SERVER → CLIENT (text JSON):   {"type": "ready",   "reference_text": "...", "total_rules": N}
  SERVER → CLIENT (text JSON):   {"type": "partial", "transcription": "...", "words_heard": N}
  SERVER → CLIENT (text JSON):   {"type": "result",  ...full EvaluatedWordAnnotation list...}
  SERVER → CLIENT (text JSON):   {"type": "error",   "message": "..."}
"""

import json
import asyncio
import tempfile
import os
from pathlib import Path as FilePath
from typing import Dict, List

from fastapi import WebSocket, WebSocketDisconnect



from services.transcription import get_transcription_service
from services.tajweed_checker import get_tajweed_checker
from models.schemas import TajweedError
from routes.visualizer import build_rule_annotation, STATUS_COLORS, TAJWEED_RULES, QURAN_DATA


# ─── Constants ────────────────────────────────────────────────────────────────

# Run a partial transcription every time we accumulate this many bytes.
# ~32 KB ≈ 1 second of 16kHz 16-bit mono PCM audio.
PARTIAL_THRESHOLD_BYTES = 32_000

# Minimum bytes before attempting any transcription (avoid Whisper on tiny clips)
MIN_AUDIO_BYTES = 16_000


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _get_surah_and_ayah(surah: int, ayah: int):
    """
    Load surah + ayah data and tajweed rules from in-memory JSON.
    Returns (surah_data, ayah_data, raw_rules) or raises ValueError.
    """
    if not QURAN_DATA.get("surahs"):
        raise ValueError("Quran data not loaded on server")

    surah_data = next(
        (s for s in QURAN_DATA["surahs"] if s.get("number") == surah),
        None
    )
    if surah_data is None:
        raise ValueError(f"Surah {surah} not found")

    if ayah > len(surah_data["ayahs"]):
        raise ValueError(f"Ayah {ayah} not found in Surah {surah}")

    ayah_data = surah_data["ayahs"][ayah - 1]
    rules_key = f"{surah}:{ayah}"
    raw_rules = TAJWEED_RULES.get(rules_key, [])

    return surah_data, ayah_data, raw_rules


def _save_buffer_to_tempfile(audio_buffer: bytearray, suffix: str = ".wav") -> str:
    """Write the accumulated audio buffer to a temp file, return its path."""
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(bytes(audio_buffer))
        return tmp.name


def _build_evaluated_annotations(
    arabic_text: str,
    raw_rules: List[Dict],
    errors_list: list,
) -> List[Dict]:
    """
    Merge Tajweed rules + acoustic check errors into a list of
    EvaluatedWordAnnotation-compatible dicts for JSON serialisation.
    """
    words = arabic_text.split()

    # Group rules by word position
    rules_by_position: Dict[int, List[Dict]] = {}
    for rule in raw_rules:
        pos = rule.get("position", -1)
        if pos >= 0:
            rules_by_position.setdefault(pos, []).append(rule)

    # Group errors by word position
    errors_by_position: Dict[int, object] = {
        err.position: err for err in errors_list
    }

    result = []
    for idx, word_text in enumerate(words):
        word_rules_raw   = rules_by_position.get(idx, [])
        rule_annotations = [
            build_rule_annotation(r).model_dump() for r in word_rules_raw
        ]

        if not word_rules_raw:
            status      = "no_rule"
            feedback_en = "No specific Tajweed rule for this word"
            feedback_ur = "اس لفظ پر کوئی مخصوص تجوید کا قاعدہ نہیں"
        elif idx in errors_by_position:
            err         = errors_by_position[idx]
            status      = "error"
            feedback_en = err.error_message_en
            feedback_ur = err.error_message_ur
        else:
            rule_type   = word_rules_raw[0]["type"]
            status      = "correct"
            feedback_en = f"✅ {rule_type.capitalize()} applied correctly!"
            feedback_ur = f"✅ {rule_type} درست ادا کیا!"

        result.append({
            "position":    idx,
            "word":        word_text,
            "rules":       rule_annotations,
            "status":      status,
            "color":       STATUS_COLORS[status],
            "feedback_en": feedback_en,
            "feedback_ur": feedback_ur,
        })

    return result


# ─── WebSocket Endpoint ───────────────────────────────────────────────────────

async def ws_recite_endpoint(websocket: WebSocket):
    """
    Live Tajweed Correction WebSocket handler.

    State machine:
      "waiting_start"  → waiting for {"type":"start", "surah":N, "ayah":N}
      "streaming"      → receiving binary audio chunks + sending partial results
      "done"           → received {"type":"done"}, run full evaluation, send result
    """
    await websocket.accept()
    print("🔌 WebSocket client connected")

    # ── Session state ─────────────────────────────────────────────────────────
    session = {
        "state":        "waiting_start",
        "surah":        None,
        "ayah":         None,
        "surah_name":   None,
        "arabic_text":  None,
        "raw_rules":    None,
        "audio_buffer": bytearray(),   # accumulates all binary audio chunks
        "bytes_since_last_partial": 0, # tracks when to fire next partial check
    }

    # Reuse the global service instances (pre-loaded by main.py lifespan)
    transcription_service = get_transcription_service()
    tajweed_service       = get_tajweed_checker()

    temp_path = None  # track any temp file for cleanup

    try:
        while True:
            # receive() returns dict with key "text", "bytes", or "disconnect"
            data = await websocket.receive()

            # ── Handle disconnection ──────────────────────────────────────────
            if data.get("type") == "websocket.disconnect":
                print("🔌 Client disconnected cleanly")
                break

            # ── Handle TEXT (JSON control messages) ───────────────────────────
            if "text" in data:
                try:
                    msg      = json.loads(data["text"])
                    msg_type = msg.get("type", "")
                except json.JSONDecodeError:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": "Invalid JSON message"
                    }))
                    continue

                # ── "start" message ───────────────────────────────────────────
                if msg_type == "start" and session["state"] == "waiting_start":
                    surah = msg.get("surah")
                    ayah  = msg.get("ayah")

                    if not surah or not ayah:
                        await websocket.send_text(json.dumps({
                            "type": "error",
                            "message": "start message must include surah and ayah numbers"
                        }))
                        continue

                    try:
                        surah_data, ayah_data, raw_rules = _get_surah_and_ayah(surah, ayah)
                    except ValueError as e:
                        await websocket.send_text(json.dumps({
                            "type": "error", "message": str(e)
                        }))
                        continue

                    # Store in session
                    session["state"]       = "streaming"
                    session["surah"]       = surah
                    session["ayah"]        = ayah
                    session["surah_name"]  = surah_data["name"]
                    session["arabic_text"] = ayah_data["text"]
                    session["raw_rules"]   = raw_rules

                    audio_url = (
                        f"https://cdn.islamic.network/quran/audio/128/ar.alafasy/"
                        f"{surah}_{ayah}.mp3"
                    )

                    print(f"✅ Session started: Surah {surah} Ayah {ayah} | "
                          f"{len(raw_rules)} rules")

                    await websocket.send_text(json.dumps({
                        "type":           "ready",
                        "reference_text": session["arabic_text"],
                        "surah_name":     session["surah_name"],
                        "total_rules":    len(raw_rules),
                        "audio_url":      audio_url,
                        "message":        "Ready to receive audio. Start reciting!"
                    }))

                # ── "done" message ────────────────────────────────────────────
                elif msg_type == "done" and session["state"] == "streaming":
                    session["state"] = "done"
                    audio_buffer = session["audio_buffer"]

                    if len(audio_buffer) < MIN_AUDIO_BYTES:
                        await websocket.send_text(json.dumps({
                            "type":    "error",
                            "message": "Audio too short — please recite more"
                        }))
                        session["state"] = "streaming"
                        continue

                    # ── Run full evaluation pipeline ──────────────────────────
                    try:
                        print(f"🔍 Running final evaluation on "
                              f"{len(audio_buffer)} bytes of audio...")

                        temp_path = _save_buffer_to_tempfile(audio_buffer)

                        # 1. Transcribe — run in thread so event loop stays alive for pings
                        transcription, confidence, word_timings = await asyncio.to_thread(
                            transcription_service.transcribe_audio, temp_path
                        )

                        # 2. Compare to reference
                        comparison       = transcription_service.compare_texts(
                            transcription, session["arabic_text"]
                        )
                        match_percentage = round(comparison.get("similarity", 0.0), 2)

                        # 3. Acoustic Tajweed check — also blocking, run in thread
                        errors_list, accuracy = await asyncio.to_thread(
                            tajweed_service.check_all_rules,
                            temp_path, session["raw_rules"], word_timings
                        )

                        # 4. Merge into color-annotated words
                        word_annotations = _build_evaluated_annotations(
                            session["arabic_text"],
                            session["raw_rules"],
                            errors_list,
                        )

                        print(f"✅ Final result: accuracy={accuracy}%, "
                              f"errors={len(errors_list)}")

                        await websocket.send_text(json.dumps({
                            "type":               "result",
                            "surah_number":       session["surah"],
                            "surah_name":         session["surah_name"],
                            "ayah_number":        session["ayah"],
                            "arabic_text":        session["arabic_text"],
                            "transcription":      transcription,
                            "transcription_match": match_percentage,
                            "overall_accuracy":   accuracy,
                            "total_rules_checked": len(session["raw_rules"]),
                            "total_errors":       len(errors_list),
                            "word_annotations":   word_annotations,
                        }))

                    except Exception as eval_err:
                        print(f"❌ Evaluation error: {eval_err}")
                        await websocket.send_text(json.dumps({
                            "type":    "error",
                            "message": f"Evaluation failed: {str(eval_err)}"
                        }))
                    finally:
                        if temp_path and os.path.exists(temp_path):
                            os.remove(temp_path)
                            temp_path = None

                    break  # Close the WebSocket after sending final result

                else:
                    await websocket.send_text(json.dumps({
                        "type":    "error",
                        "message": f"Unexpected message type '{msg_type}' in state '{session['state']}'"
                    }))

            # ── Handle BINARY (audio chunks) ──────────────────────────────────
            elif "bytes" in data and session["state"] == "streaming":
                chunk = data["bytes"]
                session["audio_buffer"].extend(chunk)
                session["bytes_since_last_partial"] += len(chunk)

                total_bytes = len(session["audio_buffer"])

                # ── Partial transcription every PARTIAL_THRESHOLD_BYTES ───────
                if (session["bytes_since_last_partial"] >= PARTIAL_THRESHOLD_BYTES
                        and total_bytes >= MIN_AUDIO_BYTES):

                    session["bytes_since_last_partial"] = 0

                    try:
                        partial_temp = _save_buffer_to_tempfile(session["audio_buffer"])
                        # Run in thread — Whisper is CPU-bound and blocks the event loop
                        partial_text, _, _ = await asyncio.to_thread(
                            transcription_service.transcribe_audio, partial_temp
                        )
                        words_heard  = len(partial_text.split())

                        print(f"⏱️  Partial: '{partial_text[:40]}...' "
                              f"({words_heard} words, {total_bytes} bytes)")

                        await websocket.send_text(json.dumps({
                            "type":         "partial",
                            "transcription": partial_text,
                            "words_heard":  words_heard,
                            "bytes_received": total_bytes,
                        }))
                    except Exception as partial_err:
                        # Don't crash the whole session for a partial failure
                        print(f"⚠️  Partial transcription failed: {partial_err}")
                    finally:
                        if os.path.exists(partial_temp):
                            os.remove(partial_temp)

    except WebSocketDisconnect:
        print("🔌 WebSocket client disconnected unexpectedly")
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
        try:
            await websocket.send_text(json.dumps({
                "type": "error", "message": str(e)
            }))
        except Exception:
            pass
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
        print("🔌 WebSocket session ended")
