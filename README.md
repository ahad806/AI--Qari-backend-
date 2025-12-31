# AI Qaari Backend API

**Quranic Recitation & Tajweed Evaluation API** built with FastAPI, Wav2Vec2, and acoustic analysis.

---

## 🌟 Features

- **🎤 Speech Transcription**: Convert Quranic recitation to Arabic text using Wav2Vec2
- **✨ Tajweed Checking**: Detect errors in Madd, Qalqalah, and Ghunnah
- **📖 Reference Data**: Access Quran text, translations, and Tajweed rules
- **🌐 RESTful API**: Easy integration with Android/Web apps
- **📊 Detailed Feedback**: Word-level comparison and error analysis

---

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- 4GB+ RAM (for ML models)

### Installation

1. **Clone or navigate to the backend directory**
   ```powershell
   cd d:\qari\backend
   ```

2. **Create a virtual environment**
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```

3. **Install dependencies**
   ```powershell
   pip install -r requirements.txt
   ```

4. **Run the server**
   ```powershell
   python main.py
   ```

5. **Open API documentation**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

---

## 📡 API Endpoints

### 1. Get Reference Data
```http
GET /api/reference/{surah}/{ayah}
```

**Example:**
```powershell
curl http://localhost:8000/api/reference/1/1
```

**Response:**
```json
{
  "surah": "الفاتحة",
  "ayah": 1,
  "arabic_text": "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
  "translation_en": "In the name of Allah...",
  "translation_ur": "شروع اللہ کے نام سے...",
  "tajweed_rules": [...],
  "audio_url": "https://cdn.islamic.network/..."
}
```

---

### 2. Transcribe Recitation
```http
POST /api/transcribe
```

**Example:**
```powershell
# Using curl
curl -X POST http://localhost:8000/api/transcribe `
  -F "audio=@recitation.wav" `
  -F "surah=1" `
  -F "ayah=1"
```

**Python Example:**
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

**Response:**
```json
{
  "success": true,
  "transcription": "بسم الله الرحمن الرحيم",
  "confidence": 0.92,
  "match_percentage": 95.5,
  "word_comparison": [
    {"position": 0, "user": "بسم", "reference": "بسم", "match": true},
    ...
  ]
}
```

---

### 3. Check Tajweed Rules
```http
POST /api/check-tajweed
```

**Example:**
```powershell
curl -X POST http://localhost:8000/api/check-tajweed `
  -F "audio=@my_recitation.wav" `
  -F "surah=1" `
  -F "ayah=1"
```

**Response:**
```json
{
  "success": true,
  "overall_accuracy": 85.5,
  "transcription_match": 90.0,
  "total_errors": 2,
  "errors": [
    {
      "rule_type": "MADD",
      "word": "ٱللَّهِ",
      "position": 1,
      "error_message_en": "Madd too short (0.3s, should be 0.5s)",
      "error_message_ur": "مد بہت چھوٹی ہے",
      "measured_value": 0.3,
      "expected_value": 0.5,
      "confidence": 0.88
    }
  ],
  "feedback_summary_en": "Found 2 error(s) in: MADD, QALQALAH",
  "feedback_summary_ur": "2 غلطیاں ملیں: MADD، QALQALAH"
}
```

---

### 4. Get All Surahs
```http
GET /api/surahs
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "number": 1,
      "name_arabic": "الفاتحة",
      "name_english": "Al-Fatiha",
      "total_ayahs": 7,
      "revelation": "Makkah"
    },
    ...
  ]
}
```

---

## 🏗️ Project Structure

```
backend/
├── main.py                 # FastAPI app entry point
├── config.py              # Configuration settings
├── requirements.txt       # Python dependencies
├── data/
│   ├── quran_text.json    # Quran text & translations
│   ├── tajweed_rules.json # Tajweed rule definitions
│   └── audio/             # Audio files (optional)
├── models/
│   ├── __init__.py
│   └── schemas.py         # Pydantic models
├── services/
│   ├── __init__.py
│   ├── transcription.py   # Wav2Vec2 service
│   └── tajweed_checker.py # Tajweed analysis
└── routes/
    ├── __init__.py
    ├── reference.py       # Reference endpoints
    ├── transcription.py   # Transcription endpoints
    └── tajweed.py         # Tajweed endpoints
```

---

## 🔧 Configuration

Edit `config.py` to customize:

```python
# Model settings
WAV2VEC2_MODEL = "jonatasgrosman/wav2vec2-large-xlsr-53-arabic"
SAMPLE_RATE = 16000

# Tajweed thresholds
TAJWEED_THRESHOLDS = {
    "madd": {
        "madd_asli": (0.35, 0.65),  # Adjust based on Qari validation
    },
    # ...
}
```

---

## 🧪 Testing

### 1. Test Reference API
```powershell
# Get Al-Fatiha, Ayah 1
Invoke-WebRequest -Uri "http://localhost:8000/api/reference/1/1" | Select-Object -ExpandProperty Content
```

### 2. Test Transcription (requires audio file)
```powershell
# Create a test audio file first, then:
$form = @{
    audio = Get-Item -Path "test.wav"
    surah = "1"
    ayah = "1"
}
Invoke-WebRequest -Uri "http://localhost:8000/api/transcribe" -Method Post -Form $form
```

### 3. Check API Health
```powershell
curl http://localhost:8000/health
```

---

## 📦 Deployment Options

### Option 1: Railway.app (Recommended - $5/month)

1. **Create `Procfile`:**
   ```
   web: uvicorn main:app --host 0.0.0.0 --port $PORT
   ```

2. **Push to GitHub and connect to Railway**

3. **Environment Variables:** None required (all settings in config.py)

---

### Option 2: Render.com (FREE tier available)

1. **Create `render.yaml`:**
   ```yaml
   services:
     - type: web
       name: ai-qaari-api
       env: python
       buildCommand: "pip install -r requirements.txt"
       startCommand: "uvicorn main:app --host 0.0.0.0 --port $PORT"
   ```

2. **Connect GitHub repo to Render**

---

### Option 3: Google Colab (FREE - For Testing)

1. **Upload files to Google Drive**
2. **Run in Colab notebook:**
   ```python
   !pip install -r requirements.txt
   !pip install pyngrok
   
   from pyngrok import ngrok
   import nest_asyncio
   
   nest_asyncio.apply()
   ngrok.set_auth_token("YOUR_TOKEN")
   
   public_url = ngrok.connect(8000)
   print(f"API URL: {public_url}")
   
   !uvicorn main:app --host 0.0.0.0 --port 8000
   ```

---

## 🛠️ Development

### Run with auto-reload (development mode)
```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Add more Surahs
Edit `data/quran_text.json` and add Surah data following the existing format.

### Add Tajweed Rules
Edit `data/tajweed_rules.json`:
```json
{
  "1:3": [
    {
      "type": "MADD",
      "position": 0,
      "letter": "ا",
      "word": "ٱلرَّحۡمَـٰنِ",
      "madd_type": "madd_asli",
      "duration_expected": 0.5,
      "description_ur": "الرحمن میں مد اصلی",
      "description_en": "Madd Asli in Ar-Rahman"
    }
  ]
}
```

---

## 📊 Model Information

### Wav2Vec2 Arabic Model
- **Model:** `jonatasgrosman/wav2vec2-large-xlsr-53-arabic`
- **Source:** Hugging Face
- **Size:** ~300MB
- **Accuracy:** 85-90% for Arabic speech
- **License:** Apache 2.0

### Audio Requirements
- **Format:** WAV, MP3, or M4A
- **Sample Rate:** 16kHz (recommended)
- **Channels:** Mono
- **Max File Size:** 10MB

---

## 🔍 Tajweed Rules Detected

### 1. Madd (مد) - Vowel Elongation
- **Madd Asli:** 2 harakaat (~0.5s)
- **Madd Wajib:** 4-5 harakaat (~0.9s)
- **Madd Lazim:** 6 harakaat (~1.5s)

### 2. Qalqalah (قلقلة) - Bouncing Sound
- **Letters:** ق ط ب ج د
- **Detection:** Intensity spike analysis (>20%)

### 3. Ghunnah (غنة) - Nasal Sound
- **Letters:** ن م (with specific conditions)
- **Detection:** Nasal frequency analysis (250-500 Hz)
- **Duration:** 2 harakaat (~0.5s)

---

## 🐛 Troubleshooting

### Issue: Model not loading
```
Error: Could not load Wav2Vec2 model
```
**Solution:** Ensure you have stable internet connection for first-time download. Model will be cached locally.

### Issue: Transcription accuracy low
**Solution:**
1. Ensure audio is clear (minimal background noise)
2. Use 16kHz sample rate
3. Speak clearly and at moderate pace
4. Consider fine-tuning model with Tanzil.net audio

### Issue: Port 8000 already in use
```powershell
# Use a different port
uvicorn main:app --port 8080
```

---

## 📈 Performance

### Benchmark (on CPU)
- **Transcription:** 2-5 seconds per 10s audio
- **Tajweed Check:** 3-7 seconds per ayah
- **Memory:** ~2GB RAM with model loaded

### Optimization Tips
1. Use GPU if available (10x faster)
2. Batch multiple requests
3. Cache frequently accessed reference data
4. Use smaller Whisper model for faster inference

---

## 🤝 Contributing

### Adding New Features
1. Create feature branch
2. Add endpoint in `routes/`
3. Add service logic in `services/`
4. Update Pydantic models in `models/schemas.py`
5. Test with `pytest`

### Improving Tajweed Accuracy
1. Collect audio samples from Qari
2. Tune thresholds in `config.py`
3. Test with validation set
4. Document changes

---

## 📚 Data Sources

### Quran Text & Audio
- **Source:** Tanzil.net
- **License:** Creative Commons BY-ND 3.0
- **Attribution:** Required in all implementations

### Tajweed Rules
- Compiled by certified Qari
- Based on Hafs recitation
- Validated against traditional sources

---

## 🔐 Security

- **CORS:** Configured for all origins (restrict in production)
- **File Upload:** 10MB limit, validated file types
- **No Authentication:** Add JWT/OAuth for production
- **Rate Limiting:** Not implemented (add for production)

---

## 📝 License

This project is for educational purposes. Quran text and audio from Tanzil.net are used under Creative Commons BY-ND 3.0 license.

---

## 🙏 Acknowledgments

- Tanzil.net for Quran text and audio
- Hugging Face for Wav2Vec2 models
- FastAPI team for the excellent framework
- Praat developers for phonetic analysis tools

---

## 📞 Support

- **Documentation:** http://localhost:8000/docs
- **Issues:** Create issue on GitHub
- **Email:** [Your contact]

---

## 🗺️ Roadmap

### Phase 1 (Current - MVP)
- ✅ Basic transcription
- ✅ Rule-based Tajweed checking
- ✅ 3 Surahs support
- ✅ REST API

### Phase 2 (Next 3 months)
- [ ] Custom TFLite model training
- [ ] 10+ Tajweed rules
- [ ] All 114 Surahs
- [ ] Forced alignment for accurate word timing
- [ ] User progress tracking

### Phase 3 (6 months)
- [ ] Real-time feedback
- [ ] Voice feedback in Urdu/Hindi
- [ ] Mobile SDK
- [ ] Offline mode

---

**Built with ❤️ for the Ummah**

*Last Updated: December 31, 2025*
