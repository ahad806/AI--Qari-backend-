"""
AI Qaari Backend API
FastAPI server for Quranic recitation transcription and Tajweed evaluation
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from routes import reference, transcription, tajweed
from services.transcription import get_transcription_service
from services.tajweed_checker import get_tajweed_checker


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown events
    Load ML models once at startup
    """
    print("🚀 Starting AI Qaari API...")
    print("📚 Loading Wav2Vec2 model for Arabic transcription...")
    
    # Pre-load models (they'll be cached in memory)
    try:
        _ = get_transcription_service()
        print("✅ Transcription service loaded successfully")
    except Exception as e:
        print(f"⚠️  Warning: Could not load transcription service: {e}")
    
    try:
        _ = get_tajweed_checker()
        print("✅ Tajweed checker loaded successfully")
    except Exception as e:
        print(f"⚠️  Warning: Could not load tajweed checker: {e}")
    
    print("✨ AI Qaari API is ready!")
    print("📖 API Documentation: http://localhost:8000/docs")
    
    yield
    
    print("🛑 Shutting down AI Qaari API...")


app = FastAPI(
    title="AI Qaari API",
    description="Quranic Recitation & Tajweed Evaluation API with real-time feedback",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for Android/Web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(reference.router, prefix="/api", tags=["📖 Reference Data"])
app.include_router(transcription.router, prefix="/api", tags=["🎤 Transcription"])
app.include_router(tajweed.router, prefix="/api", tags=["✨ Tajweed Evaluation"])


@app.get("/", summary="API Status", tags=["System"])
async def root():
    """
    Check if API is running
    """
    return {
        "status": "running",
        "message": "AI Qaari API - Quranic Recitation Learning Platform",
        "version": "1.0.0",
        "documentation": "/docs",
        "endpoints": {
            "reference": "/api/reference/{surah}/{ayah}",
            "transcribe": "/api/transcribe",
            "check_tajweed": "/api/check-tajweed",
            "surahs": "/api/surahs"
        }
    }


@app.get("/health", summary="Health Check", tags=["System"])
async def health_check():
    """
    Health check endpoint for deployment monitoring
    """
    return {
        "status": "healthy",
        "services": {
            "transcription": "available",
            "tajweed_checking": "available",
            "reference_data": "available"
        }
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,  # Auto-reload on code changes (development only)
        log_level="info"
    )
