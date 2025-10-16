# Flutter App

Cross-platform mobile app for Veo Social App.

## Structure

```
app/
├── lib/
│   ├── main.dart            # App entry point
│   ├── app_router.dart      # Navigation routes
│   ├── core/                # Core utilities
│   │   ├── auth_service.dart
│   │   └── api_client.dart
│   ├── data/                # Data layer
│   │   ├── models/          # Data models
│   │   └── repositories/    # Data repositories
│   └── features/            # Feature modules
│       ├── composer/        # Content creation
│       ├── feed/            # Feed views
│       └── profile/         # User profile
├── assets/                  # Images, fonts, etc.
├── .env.example             # Environment template
├── pubspec.yaml             # Dart dependencies
└── README.md               # This file
```

## Setup

See [Setup Guide](../docs/SETUP.md) for detailed instructions.

### Quick Start

```bash
# Copy environment template
copy .env.example .env

# Edit .env with your config

# Get dependencies
flutter pub get

# Run app
flutter run
```

## Configuration

Edit `.env` file:
- `API_BASE_URL`: Backend URL (http://localhost:8000 for local)
- `FIREBASE_*`: Firebase project configuration

## Firebase Setup

Run `flutterfire configure` to generate Firebase configuration files.

## Building

```bash
# Android
flutter build apk

# iOS (macOS only)
flutter build ios
```
