# Veo Social App

> 🎬 An open-source AI-powered social media platform built with Google's Veo 3.1 video generation and Imagen 4.0 image generation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com)

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

- 🎥 **Real-time AI Video Generation** using Google's Veo 3.1
- 🖼️ **AI Image Generation** using Imagen 4.0
- 👤 **Personalized Generation** with "Include Me" feature (up to 3 reference images)
- 📱 **Multiple Aspect Ratios** (1:1, 9:16, 16:9)
- 🔒 **Private/Public Content** control
- 📊 **Smart Feed Algorithms**:
  - Interest Feed (60%): Content based on your interactions
  - Explore Feed (25%): Trending and diverse content
  - Trending Feed (15%): Popular content across the platform
- ⚡ **Real-time Updates** with Firebase
- 🎨 **Beautiful UI** with smooth animations
- 🔐 **Authentication** (mock local auth + Firebase Auth ready)
- 📈 **Usage Limits** to control costs

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (Dart)                     │
│  ┌──────────────┬──────────────┬──────────────────────┐    │
│  │   Composer   │   Feed View  │   Profile & Settings │    │
│  └──────────────┴──────────────┴──────────────────────┘    │
└────────────────────────┬────────────────────────────────────┘
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

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.x or higher
- **Python** 3.11 or higher
- **Google Cloud Platform** account (for production)
- **Firebase** project (free tier available)

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/veo-social-app.git
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

# Install dependencies
pip install -r requirements.txt

# Copy environment template
copy .env.example .env

# Edit .env and ensure ENABLE_MOCKS=true for free testing

# Run the backend
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend will be available at `http://localhost:8000`

### 3. Flutter App Setup

```bash
cd app

# Copy environment template
copy .env.example .env

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

- **Python 3.11+** - Programming language
- **FastAPI** - Modern async web framework
- **Vertex AI SDK** - Google's AI models
- **Firebase Admin SDK** - Backend services

### Infrastructure

- **Google Cloud Platform**:
  - Vertex AI (Veo 3.1, Imagen 4.0, Gemini)
  - Cloud Firestore (NoSQL database)
  - Firebase Storage (Media storage)
- **Optional**: Cloud Run for deployment

---

## 📸 Screenshots

> 📝 TODO: Add screenshots

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

- **Google Cloud** for providing Vertex AI APIs (Veo 3.1, Imagen 4.0, Gemini)
- **Flutter Team** for the amazing framework
- **FastAPI** for the excellent Python framework
- **Firebase** for backend infrastructure

---

## 📞 Support & Community

- 🐛 **Issues**: [GitHub Issues](https://github.com/YOUR-USERNAME/veo-social-app/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/YOUR-USERNAME/veo-social-app/discussions)
- 📧 **Email**: [YOUR-EMAIL]

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
