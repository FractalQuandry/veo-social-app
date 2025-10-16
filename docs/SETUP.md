# Setup Guide - Veo Social App

This guide will help you set up and run the Veo Social App locally. The app can run in two modes:

- **Mock Mode** (Recommended for development) - Free, no API calls, uses fake data
- **Production Mode** - Uses real Vertex AI APIs (costs apply)

---

## Prerequisites

### Required Software

- **Flutter SDK** 3.3.0 or higher
  - [Install Flutter](https://docs.flutter.dev/get-started/install)
  - Run `flutter doctor` to verify installation

- **Python** 3.10 or higher
  - [Download Python](https://www.python.org/downloads/)
  - Verify: `python --version`

- **Git**
  - [Install Git](https://git-scm.com/downloads)

### Required Accounts (for Production Mode only)

- **Google Cloud Platform (GCP)** account
  - [Sign up for GCP](https://cloud.google.com/free)
  - $300 free credit for new users
  - **WARNING**: Veo/Imagen APIs cost money after free credits

- **Firebase** account (free tier available)
  - [Firebase Console](https://console.firebase.google.com/)

---

## Quick Start (Mock Mode)

The fastest way to try the app without any API setup:

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/veo-social-app.git
cd veo-social-app
```

### 2. Set Up Backend

```bash
cd backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -e .

# Copy environment template
cp .env.example .env

# Edit .env and ensure ENABLE_MOCKS=true (already set by default)
```

### 3. Run Backend

```bash
# Make sure you're in backend/ directory with activated venv
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend should start at <http://localhost:8000>. Test it:

```bash
curl http://localhost:8000/health
# Should return: {"ok": true, "mocks": true, "feed_size": 50}
```

### 4. Set Up Flutter App

Open a new terminal:

```bash
cd app

# Copy environment template
cp .env.example .env

# Edit .env and set:
# API_BASE_URL=http://localhost:8000

# Get dependencies
flutter pub get
```

### 5. Run Flutter App

```bash
# Run on connected device/emulator
flutter run

# Or specify a device
flutter devices  # List available devices
flutter run -d chrome  # Run in Chrome browser
flutter run -d <device-id>  # Run on specific device
```

The app should launch with mock data! You can browse the feed, but "Create" will show demo content.

---

## Production Setup (Real APIs)

⚠️ **WARNING**: This will incur costs on your GCP account. See [COSTS.md](COSTS.md) for pricing details.

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name (e.g., `my-veo-app`)
4. Note the **Project ID** (e.g., `my-veo-app-123456`)

### Step 2: Enable Required APIs

In the Google Cloud Console for your project:

1. Go to **APIs & Services** → **Enable APIs and Services**
2. Search for and enable each of these APIs:
   - **Vertex AI API**
   - **Cloud Storage API**
   - **Cloud Firestore API**
   - **Cloud Pub/Sub API** (optional, for async processing)
   - **Cloud Run API** (optional, for deployment)

### Step 3: Set Up Authentication

#### Option A: Application Default Credentials (Recommended)

```bash
# Install gcloud CLI: https://cloud.google.com/sdk/docs/install
gcloud auth application-default login
gcloud config set project YOUR-PROJECT-ID
```

This is the simplest method and doesn't require service account files.

#### Option B: Service Account (Alternative)

1. In Google Cloud Console, go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Name it `veo-app-backend`
4. Grant roles:
   - Vertex AI User
   - Storage Object Admin
   - Cloud Datastore User
5. Click **Create Key** → JSON
6. **IMPORTANT**: Save the JSON file securely, never commit to Git
7. Set environment variable:

   ```bash
   # Windows PowerShell:
   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
   
   # macOS/Linux:
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   ```

### Step 4: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project**
3. **Select your existing GCP project** (from Step 1)
4. Enable Google Analytics (optional)
5. Click **Create Project**

### Step 5: Configure Firebase Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started**
3. Enable sign-in methods:
   - **Email/Password** (enable)
   - **Anonymous** (enable for testing)
   - **Google** (optional)

### Step 6: Configure Firebase Storage

1. In Firebase Console, go to **Build** → **Storage**
2. Click **Get Started**
3. Start in **production mode** (or test mode for development)
4. Choose a location (e.g., `us-central1`)
5. Note the bucket name (e.g., `my-veo-app.appspot.com`)

### Step 7: Configure Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create Database**
3. Start in **production mode** (or test mode for development)
4. Choose a location (e.g., `us-central1`)
5. Copy Firestore rules from `infra/firestore.rules` to Security Rules tab
6. Copy indexes from `infra/firestore.indexes.json` to Indexes tab

### Step 8: Configure Backend Environment

Edit `backend/.env`:

```bash
# Set to false to enable real APIs
ENABLE_MOCKS=false

# Your GCP Project ID
GCP_PROJECT_ID=my-veo-app-123456

# Vertex AI region (where Veo 3.1 is available)
REGION_VERTEX=us-central1

# Firestore location
LOCATION_FIRESTORE=us-central1

# Firebase Storage bucket (from Step 6)
FIREBASE_STORAGE_BUCKET=my-veo-app.appspot.com

# Feed configuration
FEED_SIZE=50
FEED_SHARE_INTEREST=0.60
FEED_SHARE_EXPLORE=0.25
FEED_SHARE_TRENDING=0.15

# Usage limits (free tier)
MAX_FREE_VIEWS=8
MAX_FREE_DEPTH=2

# Generation timeout
GENERATE_TIMEOUT_MS=800

# Trending seed prompts (comma-separated)
TRENDING_PROMPTS=neon cyberpunk streets,cozy rainy cafe,surreal underwater city

# Optional: Pub/Sub (for async processing)
# PUBSUB_TOPIC_GENERATE=generate-requests
# PUBSUB_SUBSCRIPTION_GENERATE=generate-worker
```

### Step 9: Configure Flutter App

#### 9a. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### 9b. Generate Firebase Configuration

```bash
cd app
flutterfire configure
```

This will:

- Prompt you to select your Firebase project
- Generate `lib/firebase_options.dart` with your Firebase config
- **IMPORTANT**: This file contains your API keys - do NOT commit to public repo

#### 9c. Configure App Environment

Edit `app/.env`:

```bash
# Backend API URL
API_BASE_URL=http://localhost:8000

# For production/deployed backend:
# API_BASE_URL=https://your-backend-url.com

# Fallback URL (optional)
# API_BASE_URL_FALLBACK=http://10.0.2.2:8000

# Usage limits (must match backend)
MAX_FREE_VIEWS=8
MAX_FREE_DEPTH=2

# Feed configuration (must match backend)
FEED_SHARE_INTEREST=0.60
FEED_SHARE_EXPLORE=0.25
FEED_SHARE_TRENDING=0.15
```

### Step 10: Run with Real APIs

#### Terminal 1 - Backend

```bash
cd backend
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Check health endpoint:

```bash
curl http://localhost:8000/health
# Should return: {"ok": true, "mocks": false, "feed_size": 50}
```

#### Terminal 2 - Flutter App

```bash
cd app
flutter run
```

Now you can create real AI-generated content! 🎉

---

## Troubleshooting

### Backend Issues

**Issue**: `ModuleNotFoundError: No module named 'fastapi'`

- **Solution**: Activate virtual environment: `.venv\Scripts\activate` (Windows) or `source .venv/bin/activate` (Linux/macOS)

**Issue**: `GOOGLE_APPLICATION_CREDENTIALS not found`

- **Solution**: Run `gcloud auth application-default login` or set up service account

**Issue**: `Permission denied` when accessing Vertex AI

- **Solution**: Check that Vertex AI API is enabled and you have correct IAM roles

**Issue**: Backend starts but generates errors

- **Solution**: Check `.env` file has correct values, especially `GCP_PROJECT_ID` and `FIREBASE_STORAGE_BUCKET`

### Flutter App Issues

**Issue**: `MissingPluginException` when running app

- **Solution**: Run `flutter clean` then `flutter pub get`

**Issue**: Can't connect to backend

- **Solution**:
  - Check backend is running: `curl http://localhost:8000/health`
  - For Android emulator, use `http://10.0.2.2:8000` instead of `localhost`
  - Check `.env` has correct `API_BASE_URL`

**Issue**: `firebase_options.dart` not found

- **Solution**: Run `flutterfire configure` to generate Firebase config

**Issue**: Build fails on iOS

- **Solution**: Run `cd ios && pod install` to update CocoaPods dependencies

### Cost-Related Issues

**Issue**: Getting charged unexpectedly

- **Solution**:
  - Set `ENABLE_MOCKS=true` in backend `.env` to disable API calls
  - Set up [budget alerts](https://cloud.google.com/billing/docs/how-to/budgets) in GCP
  - Check [COSTS.md](COSTS.md) for optimization strategies

**Issue**: Quota exceeded errors

- **Solution**: Request quota increase in GCP Console or implement rate limiting

---

## Testing Your Setup

### 1. Test Backend Health

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{
  "ok": true,
  "mocks": true,  // or false in production mode
  "feed_size": 50
}
```

### 2. Test Feed Endpoint

```bash
curl -X POST http://localhost:8000/feed \
  -H "Content-Type: application/json" \
  -d '{"uid": "test-user", "feedType": "interest", "page": 1}'
```

Should return a list of feed items.

### 3. Test App Features

In the Flutter app:

1. **Browse Feed**: Scroll through the main feed
2. **Create Content**: Tap the '+' button and enter a prompt
3. **View Profile**: Check your profile and created content
4. **Test Authentication**: Try sign in/sign out

---

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand how the system works
- Read [COSTS.md](COSTS.md) to understand pricing and optimization
- Read [API_REFERENCE.md](API_REFERENCE.md) for detailed endpoint documentation
- See [CONTRIBUTING.md](../CONTRIBUTING.md) to contribute to the project

---

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/YOUR-USERNAME/veo-social-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR-USERNAME/veo-social-app/discussions)
- **Documentation**: Check other docs in the `docs/` directory

---

**Remember**: Always use mock mode during development to avoid unnecessary costs! 💰
