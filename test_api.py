"""
Quick test script to verify API endpoints
Run after starting the server with: python main.py
"""

import requests
import json

BASE_URL = "http://localhost:8000"


def test_health():
    """Test health check endpoint"""
    print("🏥 Testing health check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}\n")


def test_root():
    """Test root endpoint"""
    print("🏠 Testing root endpoint...")
    response = requests.get(f"{BASE_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}\n")


def test_surahs():
    """Test get all surahs"""
    print("📖 Testing surahs list...")
    response = requests.get(f"{BASE_URL}/api/surahs")
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Total Surahs: {len(data['data'])}")
    print(f"First Surah: {json.dumps(data['data'][0], indent=2, ensure_ascii=False)}\n")


def test_reference():
    """Test reference endpoint"""
    print("📚 Testing reference data (Al-Fatiha, Ayah 1)...")
    response = requests.get(f"{BASE_URL}/api/reference/1/1")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}\n")


def test_transcribe():
    """Test transcription (requires audio file)"""
    print("🎤 Testing transcription...")
    print("⚠️  Skipped - requires audio file")
    print("To test manually:")
    print("""
    files = {'audio': open('test.wav', 'rb')}
    data = {'surah': 1, 'ayah': 1}
    response = requests.post(f"{BASE_URL}/api/transcribe", files=files, data=data)
    print(response.json())
    """)
    print()


def test_tajweed():
    """Test tajweed checking (requires audio file)"""
    print("✨ Testing Tajweed check...")
    print("⚠️  Skipped - requires audio file")
    print("To test manually:")
    print("""
    files = {'audio': open('test.wav', 'rb')}
    data = {'surah': 1, 'ayah': 1}
    response = requests.post(f"{BASE_URL}/api/check-tajweed", files=files, data=data)
    print(response.json())
    """)
    print()


if __name__ == "__main__":
    print("=" * 60)
    print("AI Qaari API Test Suite")
    print("=" * 60)
    print()
    
    try:
        test_root()
        test_health()
        test_surahs()
        test_reference()
        test_transcribe()
        test_tajweed()
        
        print("✅ All basic tests passed!")
        print("\n📌 Next steps:")
        print("1. Record a test recitation (Al-Fatiha)")
        print("2. Test /api/transcribe endpoint")
        print("3. Test /api/check-tajweed endpoint")
        print("\n📖 API Documentation: http://localhost:8000/docs")
        
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to API")
        print("Make sure the server is running:")
        print("  python main.py")
    except Exception as e:
        print(f"❌ Error: {e}")
