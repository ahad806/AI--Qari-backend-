"""
WebSocket test client for /ws/recite endpoint
Streams a WAV file in chunks to simulate real-time microphone input

Usage:
    python test_ws.py --audio your_recitation.wav --surah 113 --ayah 1
"""

import asyncio
import websockets
import json
import argparse
import sys
import os
import tempfile
from pydub import AudioSegment


# ── Config ────────────────────────────────────────────────────────────────────

WS_URL            = "ws://localhost:8000/ws/recite"
CHUNK_SIZE_BYTES  = 32_000   # ~1 second of 16kHz 16-bit mono PCM
CHUNK_DELAY_SEC   = 1.0      # sleep between chunks to mimic real-time
PARTIAL_TIMEOUT   = 0.2      # seconds to wait for a partial response per chunk


# ── Helpers ───────────────────────────────────────────────────────────────────

def convert_to_wav(input_path: str) -> str:
    """
    Convert any audio file (mp3, m4a, etc.) to 16kHz mono WAV.
    Returns path to temp WAV file. Caller must delete it.
    """
    ext = os.path.splitext(input_path)[1].lower().lstrip(".")
    print(f"🔄 Converting {ext.upper()} → WAV (16kHz mono)...")
    audio = AudioSegment.from_file(input_path, format=ext)
    audio = audio.set_frame_rate(16000).set_channels(1)
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    audio.export(tmp.name, format="wav")
    tmp.close()
    print(f"✅ Converted: {tmp.name} ({os.path.getsize(tmp.name) / 1024:.1f} KB)")
    return tmp.name


def print_section(title: str):
    print(f"\n{'─' * 50}")
    print(f"  {title}")
    print(f"{'─' * 50}")


def print_word_annotations(annotations: list):
    STATUS_ICONS = {
        "correct":     "✅",
        "error":       "❌",
        "no_rule":     "⚪",
        "not_checked": "🟡",
    }
    for word in annotations:
        icon = STATUS_ICONS.get(word.get("status", ""), "❓")
        print(
            f"  {icon} [{word['position']}] {word['word']:<20} "
            f"status={word['status']:<12} | {word['feedback_en']}"
        )


# ── Main WebSocket test ───────────────────────────────────────────────────────

async def run_test(audio_path: str, surah: int, ayah: int):

    # Validate audio file
    if not os.path.exists(audio_path):
        print(f"❌ Audio file not found: {audio_path}")
        sys.exit(1)

    # Convert to WAV if needed
    converted_tmp = None
    ext = os.path.splitext(audio_path)[1].lower()
    if ext != ".wav":
        converted_tmp = convert_to_wav(audio_path)
        audio_path    = converted_tmp

    file_size = os.path.getsize(audio_path)
    print(f"📂 Audio file : {audio_path} ({file_size / 1024:.1f} KB)")
    print(f"📖 Target     : Surah {surah}, Ayah {ayah}")
    print(f"🌐 Connecting : {WS_URL}")

    async with websockets.connect(WS_URL) as ws:

        # ── Phase 1: Handshake ────────────────────────────────────────────────
        print_section("Phase 1 — Handshake")

        await ws.send(json.dumps({"type": "start", "surah": surah, "ayah": ayah}))
        raw = await ws.recv()
        msg = json.loads(raw)

        if msg.get("type") == "error":
            print(f"❌ Server error: {msg['message']}")
            return

        print(f"✅ Server ready!")
        print(f"   Reference text : {msg.get('reference_text', '')}")
        print(f"   Surah name     : {msg.get('surah_name', '')}")
        print(f"   Total rules    : {msg.get('total_rules', 0)}")

        # ── Phase 2: Stream audio in chunks ───────────────────────────────────
        print_section("Phase 2 — Streaming Audio")

        total_bytes_sent = 0
        chunk_number     = 0

        with open(audio_path, "rb") as f:
            while True:
                chunk = f.read(CHUNK_SIZE_BYTES)
                if not chunk:
                    break

                chunk_number     += 1
                total_bytes_sent += len(chunk)

                await ws.send(chunk)
                print(f"  📤 Chunk {chunk_number:02d} sent — {len(chunk) / 1024:.1f} KB "
                      f"(total: {total_bytes_sent / 1024:.1f} KB)")

                # Wait real-time delay
                await asyncio.sleep(CHUNK_DELAY_SEC)

                # Try to receive a partial transcription (non-blocking)
                try:
                    partial_raw = await asyncio.wait_for(ws.recv(), timeout=PARTIAL_TIMEOUT)
                    partial     = json.loads(partial_raw)

                    if partial.get("type") == "partial":
                        print(f"  🗣️  Partial heard : \"{partial.get('transcription', '')}\"")
                        print(f"       Words so far : {partial.get('words_heard', 0)}")

                except asyncio.TimeoutError:
                    pass  # No partial yet — keep streaming

        print(f"\n  ✅ Finished streaming — {chunk_number} chunks, "
              f"{total_bytes_sent / 1024:.1f} KB total")

        # ── Phase 3: Signal done, wait for full result ─────────────────────────
        print_section("Phase 3 — Final Evaluation")

        await ws.send(json.dumps({"type": "done"}))
        print("  ⏳ Waiting for server evaluation...")

        # Drain any buffered partial messages — keep receiving until we get the real result
        result = None
        while True:
            result_raw = await ws.recv()
            msg        = json.loads(result_raw)
            msg_type   = msg.get("type")

            if msg_type == "error":
                print(f"  ❌ Evaluation error: {msg['message']}")
                return
            elif msg_type == "partial":
                print(f"  🗣️  (Late partial drained): \"{msg.get('transcription', '')}\"")
                continue  # discard, wait for actual result
            elif msg_type == "result":
                result = msg
                break
            else:
                print(f"  ⚠️  Unexpected message type: {msg_type}")
                continue

        # ── Print results ──────────────────────────────────────────────────────
        print_section("Results")
        assert result is not None  # always set by the while loop above

        print(f"  Surah           : {result.get('surah_name')} ({result.get('surah_number')})")
        print(f"  Ayah            : {result.get('ayah_number')}")
        print(f"  Arabic text     : {result.get('arabic_text')}")
        print(f"  Transcription   : {result.get('transcription')}")
        print(f"  Match %         : {result.get('transcription_match')}%")
        print(f"  Tajweed accuracy: {result.get('overall_accuracy')}%")
        print(f"  Rules checked   : {result.get('total_rules_checked')}")
        print(f"  Errors found    : {result.get('total_errors')}")

        print("\n  Word-by-word breakdown:")
        print_word_annotations(result.get("word_annotations", []))

        print()

    # Clean up converted temp file
    if isinstance(converted_tmp, str) and os.path.exists(converted_tmp):
        os.remove(converted_tmp)


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="WebSocket Tajweed test client")
    parser.add_argument("--audio",  required=True,        help="Path to audio file (.wav, .mp3, .m4a)")
    parser.add_argument("--surah",  type=int, default=113, help="Surah number (default: 113)")
    parser.add_argument("--ayah",   type=int, default=1,   help="Ayah number  (default: 1)")
    args = parser.parse_args()

    asyncio.run(run_test(args.audio, args.surah, args.ayah))
