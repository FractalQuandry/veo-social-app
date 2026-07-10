# Veo Social App

> 🎬 An open-source AI-powered social media platform built with Google's Veo 3.1 video generation and Imagen 4.0 image generation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-green.svg)](https://fastapi.tiangolo.com)

---

## ⚠️ Cost Warning

**This project uses Google Cloud Platform's paid APIs.** Running this application will incur costs:

- **Veo 3.1 Video Generation**: ~$0.10-0.30 per video
- **Imagen 4.0 Image Generation**: ~$0.02-0.05 per image
- **Firebase Storage**: Pay per GB stored/transferred
- **Cloud Firestore**: Pay per read/write operation

**Estimated costs**: $10-50+ per month depending on usage.

> 💡 **Free Development Mode**: The backend supports a mock mode (`ENABLE_MOCKS=true`) for testing without API calls.

---

## ✨ Features

### 🎭 Personalized AI Generation

**The Magic: Your AI Avatar**

Upload 3 profile views (front, left profile, right profile) and the app creates a personalized AI model of YOU. Then:

- ✨ **Generate videos with yourself in them** - "Me skateboarding through cyberpunk Tokyo"
- ✨ **Create images featuring you** - "Me as a superhero in space"
- ✨ **Your likeness is stored in your profile** - One-time setup, use everywhere
- ✨ **Privacy-first** - Your profile images are your data, always under your control

The app automatically passes your profile views to Veo/Imagen when you enable "Include Me" in the composer.

### 🎨 Content Creation

- 🎥 **AI Video Generation** using Google's Veo 3.1 (up to 8 seconds)
- 🖼️ **AI Image Generation** using Imagen 4.0
- 📎 **Reference Images** - Upload up to 3 additional reference images per post (separate from profile)
  - Use for style references, objects, or scenes you want in the generation
  - Example: Upload a photo of your dog, then generate "my dog surfing in Hawaii"
- 📱 **Multiple Aspect Ratios** (1:1 square, 9:16 vertical, 16:9 horizontal)
- 🔒 **Private/Public Content** control

### 📱 Social Features

- 📊 **Smart Feed Algorithm**:
  - **Interest Feed (60%)**: Content based on your interactions and preferences
  - **Explore Feed (25%)**: Trending and diverse content discovery
  - **Trending Feed (15%)**: Popular content across the platform
- ⚡ **Real-time Updates** with Firebase
- 🎨 **Beautiful UI** with smooth animations and transitions
- 🔐 **Authentication** (mock local auth + Firebase Auth ready)
- 📈 **Usage Limits** to control costs (configurable free tier)

---

## 🪄 How It Works: The "Include Me" Feature

```
1. Setup Your Profile (One-Time)
   ┌─────────────────────────────────────────┐
   │  📸 Capture 3 Profile Views             │
   │                                          │
   │  1️⃣ Front-facing view                   │
   │  2️⃣ Left profile (45°)                  │
   │  3️⃣ Right profile (45°)                 │
   │                                          │
   │  ✅ Stored in your profile               │
   └─────────────────────────────────────────┘
                    │
                    ▼
2. Create Content
   ┌─────────────────────────────────────────┐
   │  ✏️ Write your prompt                    │
   │  "Me riding a dragon over a volcano"    │
   │                                          │
   │  ☑️ Check "Include Me"                  │
   │                                          │
   │  🎬 Generate →                           │
   └─────────────────────────────────────────┘
                    │
                    ▼
3. AI Magic Happens
   ┌─────────────────────────────────────────┐
   │  Backend automatically:                  │
   │  • Loads your 3 profile images           │
   │  • Sends to Veo 3.1 / Imagen 4.0        │
   │  • Includes subject_reference_images     │
   │                                          │
   │  🤖 AI generates YOU in the scene        │
   └─────────────────────────────────────────┘
                    │
                    ▼
4. Result
   ┌─────────────────────────────────────────┐
   │  🎉 Video/Image with YOU in it!          │
   │                                          │
   │  • Your likeness preserved               │
   │  • Natural integration into scene        │
   │  • Shareable on your feed                │
   └─────────────────────────────────────────┘
```

**Profile Images vs Reference Images:**

- **Profile Images** (3 views): Your AI avatar, stored in your profile, used when "Include Me" is enabled
- **Reference Images** (optional, up to 3 per post): Style/object/scene references for individual generations

---

## 🗺️ Architecture

```
┌────────────────────────────────────────────────────────┐
│                      Flutter App (Dart)                     │
│  ┌──────────────┬──────────────┬────────────────────┐    │
│  │   Composer   │   Feed View  │   Profile & Settings │    │
│  └──────────────┴──────────────┴────────────────────┘    │
└────────────────────────────────┬───────────────────────┘
                                 │ REST API
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                FastAPI Backend (Python)                     │
│  ┌──────────────┬──────────────┬──────────────────────┐    │
│  │  Generation  │  Feed Logic  │  Storage Management  │    │
│  └──────────────┴──────────────┴──────────────────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Vertex AI   │ │  Firestore   │ │   Firebase   │
│  (Veo/Imagen)│ │  (Database)  │ │   Storage    │
└──────────────┘ └──────────────┘ └──────────────┘
```

---

## 📁 Project Structure

```text
veo-social-app/
├── app/          # Flutter app (feed, composer, profile) — see app/README.md
├── backend/      # FastAPI backend (generation, feed, storage) — see backend/README.md
├── docs/         # Setup, architecture, costs, API reference
├── infra/        # Firestore/Storage rules, indexes, Cloud Run script, seed data
└── firebase.json # Firebase project configuration
```

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.x or higher
- **Python** 3.10 or higher
- **Google Cloud Platform** account (for production)
- **Firebase** project (free tier available)

### 1. Clone the Repository

```bash
git clone https://github.com/FractalQuandry/veo-social-app.git
cd veo-social-app
```

### 2. Backend Setup (Development Mode)

```bash
cd backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install dependencies (from pyproject.toml)
pip install -e .

# Copy environment template
# Windows:
copy .env.example .env
# macOS/Linux:
cp .env.example .env

# Edit .env and ensure ENABLE_MOCKS=true for free testing

# Run the backend
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend will be available at `http://localhost:8000`

To run the backend tests:

```bash
pip install -e ".[test]"
pytest
```

### 3. Flutter App Setup

```bash
cd app

# Copy environment template
# Windows:
copy .env.example .env
# macOS/Linux:
cp .env.example .env

# Edit .env and set API_BASE_URL=http://localhost:8000

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📖 Full Setup Guide

For production deployment with real AI generation, see:

- **[SETUP.md](docs/SETUP.md)** - Complete step-by-step setup
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and components
- **[COSTS.md](docs/COSTS.md)** - Detailed pricing breakdown
- **[API_REFERENCE.md](docs/API_REFERENCE.md)** - API documentation

---

## 🧪 Development Mode (Free)

The backend supports **mock mode** for development without incurring costs:

```bash
# In backend/.env
ENABLE_MOCKS=true
```

Mock mode will:

- ✅ Generate placeholder videos/images instantly
- ✅ Simulate feed algorithms
- ✅ Test all features without API calls
- ✅ Perfect for UI development and testing

---

## 🛠️ Tech Stack

### Frontend

- **Flutter/Dart** - Cross-platform mobile framework
- **Riverpod** - State management
- **Firebase SDK** - Auth, Storage, Firestore

### Backend

- **Python 3.10+** - Programming language
- **FastAPI** - Modern async web framework
- **Vertex AI SDK** - Google's AI models
- **Google Cloud client libraries** - Firestore, Storage, Pub/Sub

### Infrastructure

- **Google Cloud Platform**:
  - Vertex AI (Veo 3.1, Imagen 4.0)
  - Cloud Firestore (NoSQL database)
  - Firebase Storage (Media storage)
  - Pub/Sub (optional async generation worker)
- **Optional**: Cloud Run for deployment (`backend/Dockerfile` + `infra/infra/cloudrun.sh`)

---

## 📸 Screenshots & Demo

### 🎬 Video Demos

https://github.com/user-attachments/assets/a1b88694-9530-4172-9ff7-c7ef8983eae3

https://github.com/user-attachments/assets/4e9d4ee2-8e62-4fca-83de-316b074bebb7

### 🖼️ App Screenshots

<table>
  <tr>
    <td width="25%">
      <img src="docs/assets/screenshots/feed/feed-view-1.jpg" alt="Feed View" />
      <p align="center"><b>📱 Smart Feed</b><br/>AI-generated content in your personalized feed</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/feed/post-detail.jpg" alt="Post Detail" />
      <p align="center"><b>🎥 Post Detail</b><br/>View AI-generated videos and images</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/feed/profile-view.jpg" alt="Profile View" />
      <p align="center"><b>👤 Profile</b><br/>Your generated content and settings</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/composer/composer-1.jpg" alt="Composer View 1" />
      <p align="center"><b>✏️ Content Composer</b><br/>Create with text prompts and reference images</p>
    </td>
  </tr>
  <tr>
    <td width="25%">
      <img src="docs/assets/screenshots/composer/composer-2.jpg" alt="Composer View 2" />
      <p align="center"><b>🎨 Generation Options</b><br/>Choose aspect ratio, include yourself, add references</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/settings/settings-1.jpg" alt="Settings View" />
      <p align="center"><b>⚙️ Settings</b><br/>Configure app behavior and preferences</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/settings/settings-2.jpg" alt="Advanced Settings" />
      <p align="center"><b>⚙️ Advanced Settings</b><br/>Customize generation parameters</p>
    </td>
    <td width="25%">
      <img src="docs/assets/screenshots/feed/onboarding.jpg" alt="Onboarding" />
      <p align="center"><b>🎯 Onboarding</b><br/>Get started with the app</p>
    </td>
  </tr>
</table>

**More Screenshots**

<table>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/feed-view-2.jpg" alt="Feed 2" /><p align="center"><sub>Feed Alternative View</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/feed-view-3.jpg" alt="Feed 3" /><p align="center"><sub>Feed Explore Mode</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/feed-view-4.jpg" alt="Feed 4" /><p align="center"><sub>Content Browse</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/post-view-1.jpg" alt="Post 1" /><p align="center"><sub>Post Details</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/post-view-2.jpg" alt="Post 2" /><p align="center"><sub>Image View</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/content-1.jpg" alt="Content 1" /><p align="center"><sub>Content Grid</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/content-2.jpg" alt="Content 2" /><p align="center"><sub>Generation</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/content-3.jpg" alt="Content 3" /><p align="center"><sub>Results</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_1_2025-10-16_21-30-07.jpg" alt="App Photo 1" /><p align="center"><sub>App Interface</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_2_2025-10-16_21-30-07.jpg" alt="App Photo 2" /><p align="center"><sub>User Interface</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_3_2025-10-16_21-30-07.jpg" alt="App Photo 3" /><p align="center"><sub>Content Creation</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_4_2025-10-16_21-30-07.jpg" alt="App Photo 4" /><p align="center"><sub>Video Generation</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_5_2025-10-16_21-30-07.jpg" alt="App Photo 5" /><p align="center"><sub>AI Features</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_6_2025-10-16_21-30-07.jpg" alt="App Photo 6" /><p align="center"><sub>Profile Setup</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_7_2025-10-16_21-30-07.jpg" alt="App Photo 7" /><p align="center"><sub>Content Feed</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_8_2025-10-16_21-30-07.jpg" alt="App Photo 8" /><p align="center"><sub>Generation Options</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_9_2025-10-16_21-30-07.jpg" alt="App Photo 9" /><p align="center"><sub>Media Gallery</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_10_2025-10-16_21-30-07.jpg" alt="App Photo 10" /><p align="center"><sub>Settings Menu</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_11_2025-10-16_21-30-07.jpg" alt="App Photo 11" /><p align="center"><sub>User Experience</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_12_2025-10-16_21-30-07.jpg" alt="App Photo 12" /><p align="center"><sub>App Navigation</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_13_2025-10-16_21-30-07.jpg" alt="App Photo 13" /><p align="center"><sub>Content Discovery</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_14_2025-10-16_21-30-07.jpg" alt="App Photo 14" /><p align="center"><sub>Social Features</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_15_2025-10-16_21-30-07.jpg" alt="App Photo 15" /><p align="center"><sub>Generation Process</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_16_2025-10-16_21-30-07.jpg" alt="App Photo 16" /><p align="center"><sub>Result Viewing</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/feed/photo_17_2025-10-16_21-30-07.jpg" alt="App Photo 17" /><p align="center"><sub>Advanced Features</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_18_2025-10-16_21-30-07.jpg" alt="Settings Photo 18" /><p align="center"><sub>Settings Screen</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_19_2025-10-16_21-30-07.jpg" alt="Settings Photo 19" /><p align="center"><sub>Configuration</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_20_2025-10-16_21-30-07.jpg" alt="Settings Photo 20" /><p align="center"><sub>Preferences</sub></p></td>
  </tr>
  <tr>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_21_2025-10-16_21-30-07.jpg" alt="Settings Photo 21" /><p align="center"><sub>Advanced Options</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_22_2025-10-16_21-30-07.jpg" alt="Settings Photo 22" /><p align="center"><sub>User Settings</sub></p></td>
    <td width="25%"><img src="docs/assets/screenshots/settings/photo_23_2025-10-16_21-30-07.jpg" alt="Settings Photo 23" /><p align="center"><sub>App Configuration</sub></p></td>
    <td width="25%"></td>
  </tr>
</table>

### ✨ Key Features Shown

- 🎭 **Profile Image Capture**: 3-view setup for personalized generation
- 🎬 **AI Video Generation**: Veo 3.1 creating 8-second videos
- 🖼️ **AI Image Generation**: Imagen 4.0 with multiple aspect ratios
- 📸 **Reference Images**: Upload style/object references
- 📊 **Smart Feed**: Interest-based, Explore, and Trending content
- ⚡ **Real-time UI**: Smooth animations and transitions

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (mock mode + real API if possible)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Cloud** for providing Vertex AI APIs (Veo 3.1, Imagen 4.0)
- **Flutter Team** for the amazing framework
- **FastAPI** for the excellent Python framework
- **Firebase** for backend infrastructure

---

## ⚖️ Responsible AI Use

This project is designed for educational and experimental purposes. When deploying:

1. **Content Moderation**: Implement content filtering for user-generated prompts
2. **Rate Limiting**: Control API usage to manage costs
3. **Terms of Service**: Define acceptable use policies
4. **Privacy**: Handle user data responsibly
5. **Cost Management**: Set budget alerts in GCP

---

## 🗺️ Roadmap

- [ ] Add web support
- [ ] Implement content moderation
- [ ] Add video editing features
- [ ] Multi-language support
- [ ] Advanced feed personalization
- [ ] Social features (comments, likes, shares)
- [ ] Export/download capabilities

---

**Built with ❤️ for the AI community**

> ⚠️ **Reminder**: This is experimental software. Use responsibly and monitor your cloud costs!
