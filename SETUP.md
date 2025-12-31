# AI Qaari Backend - Setup Guide

## 🚀 Getting Started

### Step 1: Install Python Dependencies

```powershell
# Navigate to backend directory
cd d:\qari\backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

**Note:** First installation will take 10-15 minutes as it downloads ML models.

---

### Step 2: Verify Installation

```powershell
# Test Python imports
python -c "import fastapi; import transformers; import librosa; print('✅ All imports successful')"
```

---

### Step 3: Start the Server

```powershell
# Start FastAPI server
python main.py
```

You should see:
```
🚀 Starting AI Qaari API...
📚 Loading Wav2Vec2 model for Arabic transcription...
✅ Transcription service loaded successfully
✅ Tajweed checker loaded successfully
✨ AI Qaari API is ready!
📖 API Documentation: http://localhost:8000/docs

INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

### Step 4: Test the API

Open a new PowerShell window:

```powershell
# Activate virtual environment
cd d:\qari\backend
.\venv\Scripts\Activate.ps1

# Run test script
python test_api.py
```

Or manually test:

```powershell
# Test health endpoint
curl http://localhost:8000/health

# Test reference endpoint
curl http://localhost:8000/api/reference/1/1

# Get all Surahs
curl http://localhost:8000/api/surahs
```

---

### Step 5: Open API Documentation

Visit in your browser:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

You can test all endpoints directly from the Swagger UI!

---

## 🎤 Testing with Audio

### Create a Test Audio File

1. **Record Al-Fatiha, Ayah 1** using your phone or microphone
2. **Save as:** `test_recitation.wav` (WAV format, 16kHz if possible)
3. **Place in:** `d:\qari\backend\`

### Test Transcription

```powershell
# Using curl (PowerShell)
curl.exe -X POST "http://localhost:8000/api/transcribe" `
  -F "audio=@test_recitation.wav" `
  -F "surah=1" `
  -F "ayah=1"
```

### Test Tajweed Checking

```powershell
curl.exe -X POST "http://localhost:8000/api/check-tajweed" `
  -F "audio=@test_recitation.wav" `
  -F "surah=1" `
  -F "ayah=1"
```

---

## 🐛 Common Issues

### Issue 1: "pip is not recognized"

**Solution:**
```powershell
# Reinstall Python and check "Add Python to PATH"
# Or use:
python -m pip install -r requirements.txt
```

---

### Issue 2: "Cannot activate virtual environment"

**Solution:**
```powershell
# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then activate again
.\venv\Scripts\Activate.ps1
```

---

### Issue 3: "torch installation failed"

**Solution:**
```powershell
# Install PyTorch separately (CPU version)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Then install other requirements
pip install -r requirements.txt
```

---

### Issue 4: "Model download is slow"

**Solution:**
- First download takes 5-10 minutes (downloads ~300MB Wav2Vec2 model)
- Model is cached locally after first download
- Ensure stable internet connection

---

### Issue 5: "Port 8000 already in use"

**Solution:**
```powershell
# Use different port
uvicorn main:app --port 8080

# Or kill process using port 8000
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

---

## 📦 Adding More Quran Data

### Add More Surahs

Edit `data/quran_text.json`:

```json
{
  "surahs": [
    {
      "name": "البقرة",
      "name_english": "Al-Baqarah",
      "revelation": "Madinah",
      "ayahs": [
        {
          "number": 1,
          "text": "الم",
          "translation_en": "Alif, Lam, Meem",
          "translation_ur": "الف لام میم"
        }
      ]
    }
  ]
}
```

### Add Tajweed Rules

Edit `data/tajweed_rules.json`:

```json
{
  "2:1": [
    {
      "type": "MADD",
      "position": 0,
      "letter": "ا",
      "word": "الم",
      "madd_type": "madd_lazim",
      "duration_expected": 1.5,
      "description_ur": "الم میں مد لازم",
      "description_en": "Madd Lazim in Alif Lam Meem"
    }
  ]
}
```

---

## 🔧 Configuration

### Adjust Tajweed Thresholds

Edit `config.py`:

```python
TAJWEED_THRESHOLDS = {
    "madd": {
        "madd_asli": (0.35, 0.65),  # Increase/decrease tolerance
    }
}
```

Test with Qari validation and adjust thresholds accordingly.

---

## 🚀 Next Steps

1. ✅ API is running locally
2. 📱 Connect Android app to `http://your-ip:8000`
3. 🧪 Test with real recitations
4. 🎯 Fine-tune Tajweed thresholds with Qari
5. ☁️ Deploy to Railway/Render for production

---

## 📚 Resources

- **FastAPI Docs:** https://fastapi.tiangolo.com
- **Wav2Vec2 Model:** https://huggingface.co/jonatasgrosman/wav2vec2-large-xlsr-53-arabic
- **Tanzil.net:** http://tanzil.net/docs/download

---

**Need Help?** Check the main README.md or create an issue.
