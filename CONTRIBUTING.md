# Contributing to Veo Social App

Thank you for your interest in contributing to Veo Social App! 🎉 This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## How Can I Contribute?

### Reporting Bugs 🐛

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Screenshots** if applicable
- **Environment details** (Flutter version, Python version, OS)
- **Error messages** or logs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) when creating issues.

### Suggesting Enhancements 💡

Enhancement suggestions are welcome! When suggesting an enhancement:

- **Use a clear and descriptive title**
- **Provide detailed description** of the proposed functionality
- **Explain why this enhancement would be useful**
- **Include mockups or examples** if applicable

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Asking Questions ❓

Have a question? Use the [question template](.github/ISSUE_TEMPLATE/question.md) or check existing discussions.

### Code Contributions 💻

We welcome code contributions! Here's how:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** following our coding standards
4. **Test your changes** thoroughly
5. **Commit your changes** using conventional commits
6. **Push to your fork** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

---

## Development Setup

### Prerequisites

- **Flutter** 3.3.0 or higher
- **Dart** 3.0.0 or higher
- **Python** 3.11 or higher
- **Git**
- **Firebase account** (for Firebase setup)
- **Google Cloud account** (for Vertex AI - optional for development)

### Backend Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/veo-social-app.git
cd veo-social-app/backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -e .

# Copy environment file
cp .env.example .env

# For local development, keep ENABLE_MOCKS=true in .env
# This allows testing without GCP credentials

# Start backend server
uvicorn src.main:app --reload
```

Backend will be available at `http://localhost:8000`

### Frontend Setup

```bash
# Navigate to app directory
cd app

# Install dependencies
flutter pub get

# Copy environment file
cp .env.example .env

# Set backend URL in .env
# For local development: API_BASE_URL=http://localhost:8000

# Generate Firebase configuration (one-time setup)
# 1. Create Firebase project at https://console.firebase.google.com
# 2. Install FlutterFire CLI:
dart pub global activate flutterfire_cli

# 3. Configure Firebase:
flutterfire configure --project=YOUR-FIREBASE-PROJECT-ID

# 4. Download google-services.json for Android
# Go to Firebase Console > Project Settings > Your apps > Android app
# Download and place in app/android/app/

# Run app
flutter run
```

### Verify Setup

1. **Backend health check**: Visit `http://localhost:8000/health`
   - Should return: `{"ok": true, "mocks": true}`

2. **Backend docs**: Visit `http://localhost:8000/docs`
   - Should show FastAPI interactive documentation

3. **Flutter build**: `flutter build apk --debug`
   - Should build successfully (may have Firebase errors if not configured)

---

## Project Structure

```
veo-social-app/
├── backend/                 # FastAPI backend
│   ├── src/
│   │   ├── main.py         # FastAPI app entry point
│   │   ├── config.py       # Environment configuration
│   │   ├── models/         # Pydantic schemas
│   │   └── services/       # Business logic
│   ├── pyproject.toml      # Python dependencies
│   └── .env.example        # Environment template
│
├── app/                     # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── app_router.dart # Go Router navigation
│   │   ├── core/           # Core utilities
│   │   ├── data/           # Data layer (API, models)
│   │   └── features/       # Feature modules
│   ├── pubspec.yaml        # Flutter dependencies
│   └── .env.example        # Environment template
│
├── docs/                    # Documentation
│   ├── SETUP.md            # Setup guide
│   ├── ARCHITECTURE.md     # Architecture docs
│   ├── COSTS.md            # Cost breakdown
│   └── API_REFERENCE.md    # API documentation
│
└── infra/                   # Infrastructure
    ├── firestore.rules     # Firestore security rules
    ├── storage.rules       # Storage security rules
    └── firestore.indexes.json
```

---

## Coding Standards

### Python (Backend)

**Style Guide**: Follow [PEP 8](https://pep8.org/)

**Formatter**: Use [Black](https://black.readthedocs.io/)

```bash
# Install Black
pip install black

# Format code
black src/

# Check formatting
black --check src/
```

**Linter**: Use [Ruff](https://docs.astral.sh/ruff/)

```bash
# Install Ruff
pip install ruff

# Lint code
ruff check src/

# Auto-fix issues
ruff check --fix src/
```

**Type Hints**: Use type hints for all function parameters and return values

```python
# Good ✅
def generate_post(prompt: str, media_type: str) -> dict:
    pass

# Bad ❌
def generate_post(prompt, media_type):
    pass
```

**Docstrings**: Use Google-style docstrings

```python
def create_feed_item(post_id: str, user_id: str) -> FeedItem:
    """Create a new feed item from a post.
    
    Args:
        post_id: The unique identifier for the post
        user_id: The user ID who created the post
    
    Returns:
        A FeedItem object with populated fields
    
    Raises:
        ValueError: If post_id or user_id is empty
    """
    pass
```

### Dart/Flutter (Frontend)

**Style Guide**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)

**Formatter**: Use `dart format`

```bash
# Format all Dart files
dart format lib/

# Check formatting
dart format --output none --set-exit-if-changed lib/
```

**Linter**: Use `flutter analyze`

```bash
# Analyze code
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

**Widget Organization**:

```dart
// Good ✅ - Small, focused widgets
class PostCard extends StatelessWidget {
  final Post post;
  
  const PostCard({required this.post, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
          _buildActions(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() { /* ... */ }
  Widget _buildContent() { /* ... */ }
  Widget _buildActions() { /* ... */ }
}

// Bad ❌ - Giant widget with everything
class PostCard extends StatelessWidget {
  // 500 lines of code...
}
```

**State Management**: Use Riverpod

```dart
// Providers in separate files
final feedProvider = StateNotifierProvider<FeedController, FeedState>(
  (ref) => FeedController(ref.watch(apiClientProvider)),
);

// Consume in widgets
class FeedPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    // ...
  }
}
```

---

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no code change)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build)
- **perf**: Performance improvements

### Examples

```bash
# Feature
git commit -m "feat(feed): add infinite scroll pagination"

# Bug fix
git commit -m "fix(auth): resolve token refresh race condition"

# Documentation
git commit -m "docs(setup): add troubleshooting section for Firebase errors"

# Refactoring
git commit -m "refactor(composer): extract media picker into separate widget"

# Breaking change
git commit -m "feat(api)!: change feed endpoint response format

BREAKING CHANGE: Feed endpoint now returns pagination metadata in response.meta instead of top-level"
```

### Commit Message Rules

- Use **present tense** ("add feature" not "added feature")
- Use **imperative mood** ("move cursor to..." not "moves cursor to...")
- **Capitalize** first letter of subject
- **No period** at end of subject
- Keep subject **under 50 characters**
- Wrap body at **72 characters**
- Reference issues and PRs in footer

---

## Pull Request Process

### Before Submitting

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Run tests** and ensure they pass
4. **Run linters** and fix issues
5. **Update CHANGELOG** (if applicable)
6. **Rebase on main** to ensure clean history

### PR Title

Follow the same format as commit messages:

```
feat(feed): add video playback controls
fix(auth): handle expired tokens gracefully
```

### PR Description

Use the PR template and include:

- **Summary** of changes
- **Motivation** - why is this change needed?
- **Testing** - how did you test this?
- **Screenshots** - for UI changes
- **Breaking changes** - if any
- **Checklist** - complete all items

### Review Process

1. **Automated checks** must pass (linting, tests)
2. **At least one approval** from maintainers
3. **All conversations resolved**
4. **No merge conflicts**
5. Maintainers will merge using **squash and merge**

### After Merge

- Your PR will be squashed into a single commit
- Delete your feature branch
- Pull latest main: `git pull origin main`

---

## Testing Guidelines

### Backend Tests

Located in `backend/src/tests/`

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest src/tests/test_feed.py

# Run specific test
pytest src/tests/test_feed.py::test_create_feed_item
```

**Writing Tests**:

```python
import pytest
from src.services import feed

def test_create_feed_item():
    """Test feed item creation."""
    item = feed.create_feed_item(
        post_id="test-post",
        user_id="test-user"
    )
    
    assert item.post_id == "test-post"
    assert item.user_id == "test-user"
    assert item.score > 0
```

### Frontend Tests

Located in `app/test/`

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/feed/feed_controller_test.dart
```

**Writing Tests**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('FeedController', () {
    test('loads feed items successfully', () async {
      // Arrange
      final controller = FeedController(mockApiClient);
      
      // Act
      await controller.loadFeed();
      
      // Assert
      expect(controller.state.items.length, greaterThan(0));
      expect(controller.state.isLoading, false);
    });
  });
}
```

### Test Coverage

- Aim for **>80% coverage** for new code
- **100% coverage** for critical paths (auth, payments)
- Don't test generated code or UI widgets (use integration tests instead)

---

## Documentation

### When to Update Docs

Update documentation when you:

- Add a new **feature**
- Change **API endpoints**
- Modify **configuration** options
- Update **dependencies**
- Change **setup** process
- Fix a **common issue** (add to troubleshooting)

### Documentation Locations

- **Setup guides**: `docs/SETUP.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **API docs**: `docs/API_REFERENCE.md`
- **Cost info**: `docs/COSTS.md`
- **Code comments**: Inline in source files
- **README**: Main `README.md` (keep concise)

### Documentation Style

- Use **clear, simple language**
- Include **code examples**
- Add **screenshots** for UI features
- Use **step-by-step instructions**
- Test instructions on a **fresh setup**
- Keep **up to date** with code changes

---

## Getting Help

### Resources

- 📖 **Documentation**: Check `docs/` directory
- 🐛 **Issues**: Search existing issues
- 💬 **Discussions**: Use GitHub Discussions
- 📧 **Contact**: Reach out to maintainers

### Asking Good Questions

When asking for help:

1. **Search first** - check docs and existing issues
2. **Provide context** - what are you trying to do?
3. **Show your work** - what have you tried?
4. **Include details** - error messages, logs, versions
5. **Format code** - use code blocks for readability

---

## Recognition

Contributors will be:

- Listed in `README.md` Contributors section
- Mentioned in release notes
- Credited in commit history

Thank you for contributing! 🙏

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Questions?** Feel free to open an issue with the "question" label or reach out to the maintainers.

Happy coding! 🚀
