# Architecture - Veo Social App

This document describes the system architecture, components, data flow, and key design decisions for the Veo Social App.

---

## System Overview

Veo Social App is a TikTok-style social media application that uses AI to generate images and videos based on text prompts. The system consists of:

- **Flutter Mobile App** (Frontend)
- **FastAPI Backend** (API Layer)
- **Firebase Services** (Auth, Storage, Database)
- **Google Vertex AI** (AI Generation)

```
┌─────────────────┐
│  Flutter App    │ ← User Interface (iOS/Android/Web)
│  (Dart/Flutter) │
└────────┬────────┘
         │ HTTP/REST
         ▼
┌─────────────────┐
│ FastAPI Backend │ ← Business Logic & API
│  (Python)       │
└────────┬────────┘
         │
    ┌────┴────┬────────────┬──────────────┐
    │         │            │              │
    ▼         ▼            ▼              ▼
┌────────┐ ┌──────┐ ┌───────────┐ ┌──────────────┐
│Firebase│ │Cloud │ │ Vertex AI │ │   Firestore  │
│  Auth  │ │Storage│ │ (Veo/     │ │   Database   │
│        │ │       │ │  Imagen)  │ │              │
└────────┘ └──────┘ └───────────┘ └──────────────┘
```

---

## Component Architecture

### 1. Flutter App (Frontend)

**Technology Stack**:

- **Framework**: Flutter 3.3+
- **State Management**: Riverpod (reactive state management)
- **Routing**: GoRouter (declarative routing)
- **HTTP Client**: Dio (with retry and timeout)
- **Firebase SDKs**: firebase_auth, cloud_firestore, firebase_storage

**Key Features**:

- **Feed Browsing**: Infinite scroll TikTok-style feed
- **Content Creation**: Compose screen with prompt input and reference images
- **Authentication**: Email/password and anonymous auth
- **Profile Management**: User profiles with content history
- **Offline Support**: Cached images/videos for offline viewing

**Directory Structure**:

```
app/lib/
├── main.dart                  # App entry point
├── app_router.dart            # Navigation configuration
├── core/
│   ├── env.dart               # Environment configuration
│   └── theme/                 # App theme and styling
├── features/
│   ├── auth/                  # Authentication screens & logic
│   ├── feed/                  # Feed browsing & display
│   ├── composer/              # Content creation
│   ├── profile/               # User profiles
│   └── post/                  # Individual post display
└── data/
    ├── api/                   # Backend API client
    ├── models/                # Data models (Post, User, etc.)
    └── providers/             # Riverpod providers
```

**State Management Pattern**:

- **Providers**: Riverpod providers for global state
- **Notifiers**: StateNotifier for complex state logic
- **Async**: FutureProvider and StreamProvider for async data
- **Local State**: StatefulWidget for UI-only state

### 2. FastAPI Backend

**Technology Stack**:

- **Framework**: FastAPI 0.111.0 (Python async web framework)
- **HTTP Server**: Uvicorn (ASGI server)
- **Dependencies**:
  - `google-cloud-aiplatform` - Vertex AI integration
  - `google-cloud-firestore` - Database access
  - `google-cloud-storage` - File storage
  - `python-dotenv` - Environment configuration

**Key Components**:

#### API Layer (`src/main.py`)

- REST endpoints for feed, generation, profiles
- CORS middleware for cross-origin requests
- Request validation with Pydantic models
- Error handling and logging

#### Services Layer (`src/services/`)

- **Generation Service**: Interfaces with Vertex AI (Veo, Imagen, Gemini)
- **Feed Service**: Builds personalized feeds based on user activity
- **Storage Service**: Manages Cloud Storage uploads/downloads
- **Store Service**: Abstracts Firestore database operations
- **Moderation Service**: Content moderation (basic implementation)
- **Recommendation Service**: Topic selection for feed diversity

#### Configuration (`src/config.py`)

- Environment variable loading
- Settings singleton pattern
- Type-safe configuration with defaults
- Mock mode toggle

**Directory Structure**:

```
backend/src/
├── main.py                    # FastAPI app & endpoints
├── config.py                  # Configuration management
├── models/
│   └── schemas.py             # Pydantic models (request/response)
├── services/
│   ├── generation.py          # AI generation logic
│   ├── feed.py                # Feed building logic
│   ├── storage.py             # Cloud Storage operations
│   ├── store.py               # Firestore operations
│   ├── moderation.py          # Content moderation
│   ├── reco.py                # Recommendation engine
│   └── mocks.py               # Mock data for development
└── tests/                     # Unit tests
```

### 3. Firebase Services

#### Firebase Authentication

- **Purpose**: User identity management
- **Methods**: Email/password, Anonymous
- **Integration**: Firebase SDK in Flutter app
- **Backend**: Verifies Firebase ID tokens (not yet implemented)

#### Cloud Firestore (NoSQL Database)

- **Purpose**: Store posts, user profiles, feed associations
- **Structure**: See [Firestore Schema](#firestore-schema) below
- **Access**: Backend uses Admin SDK, App uses client SDK
- **Security**: Firestore security rules in `infra/firestore.rules`

#### Firebase Storage (Cloud Storage)

- **Purpose**: Store generated images and videos
- **Structure**:
  - `media/{postId}/image.jpg` - Generated images
  - `media/{postId}/video.mp4` - Generated videos
  - `profile/{uid}/base_image.jpg` - User profile images
  - `profile/{uid}/reference_{n}.jpg` - Reference images
- **Access**: Backend uses Admin SDK, App uses client SDK
- **Security**: Storage security rules in `infra/storage.rules`

### 4. Google Vertex AI

#### Veo 3.1 (Video Generation)

- **Model**: `imagen-3.0-generate-002` (image gen) or `veo-001` (video gen)
- **Input**: Text prompt + optional reference images (up to 3)
- **Output**: GCS URI to generated video (MP4)
- **Speeds**: Fast (~6-20s) or Slow (~30-60s, higher quality)
- **Pricing**: ~$0.065/video (Fast), ~$0.13/video (Slow)

#### Imagen 4.0 (Image Generation)

- **Model**: `imagen-3.0-generate-002`
- **Input**: Text prompt + optional reference images
- **Output**: Base64-encoded image or GCS URI
- **Speed**: ~2-5 seconds
- **Pricing**: ~$0.02/image

#### Gemini (Prompt Enhancement)

- **Model**: `gemini-1.5-flash-002`
- **Purpose**: Enhance user prompts for better generation results
- **Input**: User's raw prompt
- **Output**: Enhanced, more detailed prompt
- **Pricing**: Very cheap (~$0.0001/prompt)

---

## Data Flow

### 1. User Creates Content (Composer Flow)

```
[User enters prompt] 
       ↓
[Flutter App validates input]
       ↓
[App uploads reference images to Firebase Storage] (if any)
       ↓
[App sends POST /gen/image or /gen/video]
       ↓
[Backend enhances prompt with Gemini] (optional)
       ↓
[Backend calls Vertex AI (Veo/Imagen)]
       ↓ 
    FAST MODE (Images):
    ↓
[Imagen returns base64 image immediately]
       ↓
[Backend uploads to Cloud Storage]
       ↓
[Backend saves post to Firestore]
       ↓
[Backend returns {jobId, status: "ready", etaMs: 0}]
       ↓
[App displays generated content immediately]

    SLOW MODE (Videos):
    ↓
[Veo returns job ID, video processing async]
       ↓
[Backend saves pending job to Firestore]
       ↓
[Backend returns {jobId, status: "pending", etaMs: 30000}]
       ↓
[App shows loading state with ETA]
       ↓
[User waits, app polls job status]
       ↓
[Once ready, backend updates Firestore post]
       ↓
[App refreshes feed, shows generated video]
```

### 2. User Browses Feed

```
[User scrolls feed]
       ↓
[App sends POST /feed with {uid, feedType, page}]
       ↓
[Backend queries Firestore for user's feed]
       ↓
[Backend applies feed algorithm]:
    - 60% Interest (based on user interactions)
    - 25% Explore (trending/popular content)
    - 15% Trending (seed topics)
       ↓
[Backend returns paginated list of posts]
       ↓
[App displays posts in feed]
       ↓
[User taps post to view]
       ↓
[App sends POST /posts/{postId}/view]
       ↓
[Backend records view in Firestore]
       ↓
[App plays video or shows image fullscreen]
```

### 3. Authentication Flow

```
[User enters email/password]
       ↓
[App calls Firebase Auth SDK]
       ↓
[Firebase returns ID token]
       ↓
[App stores token in local storage]
       ↓
[App includes token in all API requests] (future)
       ↓
[Backend verifies token with Firebase] (future)
       ↓
[Backend authorizes request]
```

---

## Firestore Schema

### Collection: `posts`

Document ID: Auto-generated

```json
{
  "id": "auto-generated-id",
  "userId": "user-uid",
  "prompt": "A futuristic city at sunset",
  "mediaUrl": "https://storage.googleapis.com/bucket/media/post-id/video.mp4",
  "mediaType": "video",
  "aspectRatio": "9:16",
  "status": "ready",
  "isPrivate": false,
  "createdAt": 1234567890.0,
  "views": 42,
  "seed": 12345,
  "duration": 5,
  "referenceImages": [
    "gs://bucket/profile/uid/base_image.jpg"
  ]
}
```

**Indexes**:

- `userId` + `createdAt DESC` (user's posts)
- `status` + `createdAt DESC` (ready posts)

### Collection: `users`

Document ID: User UID (from Firebase Auth)

```json
{
  "uid": "user-uid",
  "email": "user@example.com",
  "displayName": "User Name",
  "createdAt": 1234567890.0,
  "profileImages": {
    "baseImage": "profile/uid/base_image.jpg",
    "referenceImages": [
      "profile/uid/reference_0.jpg",
      "profile/uid/reference_1.jpg"
    ]
  },
  "budget": {
    "images": 10,
    "videos": 5
  },
  "settings": {
    "includeMe": true
  }
}
```

### Collection: `feeds`

Document ID: `{userId}_{feedType}` (e.g., `user-uid_interest`)

```json
{
  "userId": "user-uid",
  "feedType": "interest",
  "posts": [
    {
      "postId": "post-id-1",
      "score": 0.95,
      "reasons": ["composer"],
      "attachedAt": 1234567890.0
    },
    {
      "postId": "post-id-2",
      "score": 0.87,
      "reasons": ["interest", "topic-match"],
      "attachedAt": 1234567891.0
    }
  ],
  "updatedAt": 1234567892.0
}
```

**Note**: Feed documents store references to posts, sorted by score/timestamp.

### Collection: `jobs` (Pending Generations)

Document ID: Job ID (UUID)

```json
{
  "jobId": "uuid-job-id",
  "userId": "user-uid",
  "status": "pending",
  "post": {
    "id": "post-id",
    "prompt": "...",
    "mediaType": "video"
  },
  "ready_at": 1234567920.0,
  "reasons": ["composer"],
  "createdAt": 1234567890.0
}
```

---

## Feed Algorithm

The feed algorithm balances personalization with discovery:

### Feed Types

1. **Interest Feed** (60% of content)
   - Based on user's past interactions
   - Topics related to user's created content
   - Similar styles to liked posts

2. **Explore Feed** (25% of content)
   - Trending across all users
   - High view/like count
   - Recent popular posts

3. **Trending Feed** (15% of content)
   - Seed topics from configuration
   - Evergreen content themes
   - Ensures feed always has content

### Scoring Algorithm

```python
# Pseudo-code for post scoring
score = 0.0

# User created this content
if post.userId == current_user:
    score += 1.0  # Highest priority

# Topic match with user interests
if post.topic in user.interests:
    score += 0.8

# Popularity (views, likes)
popularity_score = log(post.views + 1) / 10
score += popularity_score

# Recency (newer content prioritized)
age_hours = (now - post.createdAt) / 3600
recency_score = 1.0 / (1 + age_hours / 24)
score += recency_score * 0.5

# Diversity (penalize similar content)
if similar_in_feed:
    score *= 0.5

return score
```

### Pagination

- Feed endpoint returns 50 posts per page (configurable)
- Each request includes `page` parameter
- Backend returns `hasMore` boolean
- Client loads more on scroll

---

## API Endpoints

See [API_REFERENCE.md](API_REFERENCE.md) for detailed endpoint documentation.

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/feed` | Get personalized feed |
| POST | `/gen/image` | Generate image |
| POST | `/gen/video` | Generate video |
| GET | `/posts/{postId}` | Get single post |
| POST | `/posts/{postId}/view` | Record post view |
| GET | `/profile/{uid}` | Get user profile |

---

## State Management (Riverpod)

### Key Providers

```dart
// API client provider
final apiClientProvider = Provider<MyWayApi>((ref) {
  return MyWayApi();
});

// Authentication state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Feed provider (paginated)
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(apiClientProvider));
});

// Current user provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  // Fetch user data from Firestore
  return fetchUserData(authUser.uid);
});

// Post provider (individual post)
final postProvider = FutureProvider.family<Post, String>((ref, postId) async {
  return ref.read(apiClientProvider).getPost(postId);
});
```

### State Flow Example (Feed Loading)

```dart
// User scrolls to bottom of feed
onScrollEnd() {
  final feedNotifier = ref.read(feedProvider.notifier);
  feedNotifier.loadMore();
}

// FeedNotifier loads next page
class FeedNotifier extends StateNotifier<FeedState> {
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await api.getFeed(
        uid: currentUserId,
        feedType: 'interest',
        page: state.currentPage + 1,
      );
      
      state = state.copyWith(
        posts: [...state.posts, ...response.items],
        currentPage: response.nextPage,
        hasMore: response.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

---

## Security Considerations

### Authentication

- Firebase Authentication for user identity
- ID tokens for API authorization (to be implemented)
- Secure token storage in Flutter SecureStorage

### Authorization

- Users can only modify their own content
- Private posts only visible to creator
- Firestore security rules enforce access control

### Content Moderation

- Basic prompt moderation in backend
- Vertex AI has built-in safety filters
- User reporting system (to be implemented)

### Data Privacy

- User emails stored securely in Firebase Auth
- Profile data in Firestore with security rules
- No PII in generated content metadata

---

## Performance Optimizations

### Backend

- **Async I/O**: FastAPI's async endpoints for concurrent requests
- **Connection Pooling**: Reuse Firestore/Storage connections
- **Caching**: Cache trending topics and fallback content
- **Mock Mode**: Fast responses for development without API calls

### Frontend

- **Image Caching**: `cached_network_image` for image caching
- **Lazy Loading**: Only load visible posts in feed
- **Pagination**: Load feed in chunks (50 posts at a time)
- **Video Preloading**: Preload next video while current plays
- **State Persistence**: Persist feed state across app restarts

### Storage

- **CDN**: Firebase Storage serves content via CDN
- **Compression**: Videos compressed to reasonable quality
- **Aspect Ratios**: Use 9:16 for optimal mobile viewing

---

## Deployment Architecture (Future)

```
┌──────────────┐
│   Flutter    │
│   Web App    │ ← Static hosting (Firebase Hosting)
└──────────────┘

┌──────────────┐
│   Flutter    │
│ Mobile Apps  │ ← iOS App Store, Google Play
└──────────────┘

┌──────────────┐
│   FastAPI    │
│   Backend    │ ← Cloud Run (serverless containers)
└──────────────┘

┌──────────────┐
│   Pub/Sub    │
│   Worker     │ ← Cloud Run Jobs (async processing)
└──────────────┘
```

**Benefits**:

- Auto-scaling based on traffic
- Pay only for what you use
- No server management
- Global CDN for static assets

---

## Future Enhancements

- [ ] Real-time feed updates (WebSocket or Firebase Realtime)
- [ ] Like/comment/share features
- [ ] Push notifications for feed updates
- [ ] Advanced recommendation engine (ML-based)
- [ ] Content search and discovery
- [ ] User following/followers
- [ ] Analytics dashboard
- [ ] A/B testing framework
- [ ] Advanced moderation (image/video analysis)
- [ ] Multi-language support

---

## Architecture Decisions

### Why FastAPI?

- Modern Python framework with excellent async support
- Auto-generated API documentation (OpenAPI)
- Fast performance comparable to Node.js
- Type safety with Pydantic models

### Why Flutter?

- Cross-platform (iOS, Android, Web) from single codebase
- Excellent performance with native compilation
- Rich UI components and animations
- Strong community and ecosystem

### Why Firestore?

- Serverless (no database management)
- Real-time sync capabilities
- Offline support built-in
- Scales automatically

### Why Vertex AI?

- State-of-the-art models (Veo 3.1, Imagen 4.0)
- Integrated with Google Cloud ecosystem
- No need to host/manage models
- Built-in safety features

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-16
