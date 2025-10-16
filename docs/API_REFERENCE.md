# API Reference - Veo Social App

This document provides detailed documentation for all backend API endpoints.

**Base URL**: `http://localhost:8000` (development)

---

## Authentication

🚧 **Not Yet Implemented**: Currently, the API does not require authentication. This is a security risk and should be addressed before production deployment.

**Future Implementation**:

- All endpoints will require a Firebase ID token in the `Authorization` header
- Format: `Authorization: Bearer <firebase-id-token>`
- Backend will verify tokens with Firebase Admin SDK

---

## Common Headers

All requests should include:

```http
Content-Type: application/json
```

Future authentication header:

```http
Authorization: Bearer <firebase-id-token>
```

---

## Endpoints

### Health Check

#### `GET /health`

Check if the API is running and get configuration info.

**Parameters**: None

**Response**:

```json
{
  "ok": true,
  "mocks": true,
  "feed_size": 50
}
```

**Response Fields**:

- `ok` (boolean): Always `true` if server is running
- `mocks` (boolean): Whether mock mode is enabled
- `feed_size` (integer): Number of posts returned per feed page

**Example**:

```bash
curl http://localhost:8000/health
```

---

### Get Feed

#### `POST /feed`

Get a paginated, personalized feed for a user.

**Request Body**:

```json
{
  "uid": "user-123",
  "feedType": "interest",
  "page": 1
}
```

**Request Fields**:

- `uid` (string, required): User ID
- `feedType` (string, required): One of `"interest"`, `"explore"`, `"trending"`
- `page` (integer, required): Page number (starts at 1)

**Response**:

```json
{
  "items": [
    {
      "slot": "READY",
      "post": {
        "id": "post-123",
        "userId": "user-456",
        "prompt": "A futuristic city at sunset",
        "mediaUrl": "https://storage.googleapis.com/bucket/media/post-123/video.mp4",
        "mediaType": "video",
        "aspectRatio": "9:16",
        "status": "ready",
        "isPrivate": false,
        "createdAt": 1234567890.0,
        "views": 42,
        "seed": 12345,
        "duration": 5
      },
      "reason": ["composer"]
    }
  ],
  "hasMore": true,
  "nextPage": 2
}
```

**Response Fields**:

- `items` (array): List of feed items
  - `slot` (string): `"READY"`, `"PENDING"`, or `"FALLBACK"`
  - `post` (object): Post details (see [Post Model](#post-model))
  - `jobId` (string, optional): Job ID if status is pending
  - `reason` (array): Reason for inclusion (e.g., `["composer"]`, `["interest"]`)
- `hasMore` (boolean): Whether more posts are available
- `nextPage` (integer): Next page number to request

**Feed Types**:

- `"interest"`: Personalized based on user's interests and interactions
- `"explore"`: Trending and popular content from all users
- `"trending"`: Content based on trending topics and seed prompts

**Example**:

```bash
curl -X POST http://localhost:8000/feed \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "user-123",
    "feedType": "interest",
    "page": 1
  }'
```

**Error Responses**:

- `400 Bad Request`: Invalid request body
- `500 Internal Server Error`: Server error

---

### Generate Image

#### `POST /gen/image`

Generate an image using Imagen 4.0.

**Request Body**:

```json
{
  "uid": "user-123",
  "type": "image",
  "prompt": "A cozy coffee shop on a rainy day",
  "aspect": "1:1",
  "seed": 42,
  "isPrivate": false,
  "includeMe": true,
  "referenceImagePaths": [
    "profile/user-123/reference_0.jpg",
    "profile/user-123/reference_1.jpg"
  ]
}
```

**Request Fields**:

- `uid` (string, required): User ID
- `type` (string, required): Must be `"image"`
- `prompt` (string, required): Text description of desired image
- `aspect` (string, optional): Aspect ratio - `"1:1"`, `"16:9"`, `"9:16"`, `"4:3"`, `"3:4"` (default: `"1:1"`)
- `seed` (integer, optional): Random seed for reproducibility
- `isPrivate` (boolean, optional): Whether post is private (default: `false`)
- `includeMe` (boolean, optional): Include user's profile image as reference (default: `false`)
- `referenceImagePaths` (array, optional): List of reference image paths in Cloud Storage (max 3 total including profile image)

**Response** (Fast - Image Ready Immediately):

```json
{
  "jobId": "uuid-job-id",
  "status": "ready",
  "etaMs": 0
}
```

**Response Fields**:

- `jobId` (string): Unique job identifier
- `status` (string): `"ready"` (image generated) or `"pending"` (processing)
- `etaMs` (integer): Estimated time to completion in milliseconds (0 if ready)

**Example**:

```bash
curl -X POST http://localhost:8000/gen/image \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "user-123",
    "type": "image",
    "prompt": "A serene mountain landscape at dawn",
    "aspect": "16:9"
  }'
```

**Error Responses**:

- `400 Bad Request`: Invalid request (wrong type, missing fields)
- `500 Internal Server Error`: Generation failed

---

### Generate Video

#### `POST /gen/video`

Generate a video using Veo 3.1.

**Request Body**:

```json
{
  "uid": "user-123",
  "type": "video",
  "prompt": "A futuristic car driving through neon-lit streets",
  "aspect": "9:16",
  "seed": 42,
  "duration": 5,
  "audio": false,
  "isPrivate": false,
  "includeMe": true,
  "referenceImagePaths": [
    "profile/user-123/reference_0.jpg"
  ]
}
```

**Request Fields**:

- `uid` (string, required): User ID
- `type` (string, required): Must be `"video"`
- `prompt` (string, required): Text description of desired video
- `aspect` (string, optional): Aspect ratio - `"16:9"` or `"9:16"` (default: `"9:16"`)
- `seed` (integer, optional): Random seed for reproducibility
- `duration` (integer, optional): Video duration in seconds - `5` or `10` (default: `5`)
- `audio` (boolean, optional): Generate with audio (default: `false`)
- `isPrivate` (boolean, optional): Whether post is private (default: `false`)
- `includeMe` (boolean, optional): Include user's profile image as reference (default: `false`)
- `referenceImagePaths` (array, optional): List of reference image paths in Cloud Storage (max 3 total)

**Response** (Pending - Video Processing Async):

```json
{
  "jobId": "uuid-job-id",
  "status": "pending",
  "etaMs": 30000
}
```

**Response Fields**:

- `jobId` (string): Unique job identifier
- `status` (string): `"pending"` (processing) or `"ready"` (unlikely for videos)
- `etaMs` (integer): Estimated time to completion in milliseconds

**Polling**:
After receiving a pending response, the client should:

1. Wait for `etaMs` milliseconds
2. Refresh the feed to check if post is ready
3. Repeat if still pending (with exponential backoff)

**Example**:

```bash
curl -X POST http://localhost:8000/gen/video \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "user-123",
    "type": "video",
    "prompt": "Waves crashing on a tropical beach",
    "aspect": "9:16",
    "duration": 5
  }'
```

**Error Responses**:

- `400 Bad Request`: Invalid request (wrong type, invalid duration)
- `500 Internal Server Error`: Generation failed

---

### Get Single Post

🚧 **Not Yet Implemented** - Planned endpoint

#### `GET /posts/{postId}`

Get details of a single post.

**Parameters**:

- `postId` (path): Post ID

**Response**:

```json
{
  "id": "post-123",
  "userId": "user-456",
  "prompt": "A futuristic city",
  "mediaUrl": "https://storage.googleapis.com/...",
  "mediaType": "video",
  "aspectRatio": "9:16",
  "status": "ready",
  "isPrivate": false,
  "createdAt": 1234567890.0,
  "views": 42
}
```

**Example**:

```bash
curl http://localhost:8000/posts/post-123
```

---

### Record Post View

🚧 **Not Yet Implemented** - Planned endpoint

#### `POST /posts/{postId}/view`

Record that a user viewed a post (for analytics and recommendations).

**Parameters**:

- `postId` (path): Post ID

**Request Body**:

```json
{
  "uid": "user-123"
}
```

**Response**:

```json
{
  "ok": true
}
```

**Example**:

```bash
curl -X POST http://localhost:8000/posts/post-123/view \
  -H "Content-Type: application/json" \
  -d '{"uid": "user-123"}'
```

---

### Get User Profile

🚧 **Not Yet Implemented** - Planned endpoint

#### `GET /profile/{uid}`

Get a user's profile information.

**Parameters**:

- `uid` (path): User ID

**Response**:

```json
{
  "uid": "user-123",
  "displayName": "John Doe",
  "createdAt": 1234567890.0,
  "postCount": 42,
  "viewCount": 1337
}
```

**Example**:

```bash
curl http://localhost:8000/profile/user-123
```

---

## Data Models

### Post Model

```json
{
  "id": "post-123",
  "userId": "user-456",
  "prompt": "A futuristic city at sunset",
  "mediaUrl": "https://storage.googleapis.com/bucket/media/post-123/video.mp4",
  "mediaType": "video",
  "aspectRatio": "9:16",
  "status": "ready",
  "isPrivate": false,
  "createdAt": 1234567890.0,
  "views": 42,
  "seed": 12345,
  "duration": 5,
  "referenceImages": [
    "gs://bucket/profile/user-456/base_image.jpg"
  ]
}
```

**Fields**:

- `id` (string): Unique post identifier
- `userId` (string): ID of user who created the post
- `prompt` (string): Text prompt used to generate content
- `mediaUrl` (string): URL to generated image or video
- `mediaType` (string): `"image"` or `"video"`
- `aspectRatio` (string): Aspect ratio (e.g., `"9:16"`, `"1:1"`)
- `status` (string): `"pending"`, `"ready"`, or `"error"`
- `isPrivate` (boolean): Whether post is private (only visible to creator)
- `createdAt` (float): Unix timestamp of creation
- `views` (integer): Number of times post was viewed
- `seed` (integer, optional): Random seed used for generation
- `duration` (integer, optional): Video duration in seconds (videos only)
- `referenceImages` (array, optional): List of reference image GCS URIs

---

## Error Codes

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `200` | OK | Request succeeded |
| `400` | Bad Request | Invalid request parameters |
| `401` | Unauthorized | Missing or invalid authentication (future) |
| `403` | Forbidden | User not authorized for resource (future) |
| `404` | Not Found | Resource not found |
| `429` | Too Many Requests | Rate limit exceeded (future) |
| `500` | Internal Server Error | Server error |
| `503` | Service Unavailable | Service temporarily unavailable |

### Error Response Format

```json
{
  "detail": "Error message describing what went wrong"
}
```

**Example**:

```json
{
  "detail": "type does not match endpoint"
}
```

---

## Rate Limiting

🚧 **Not Yet Implemented** - Recommended for production

**Recommended limits**:

- `/feed`: 100 requests/minute per user
- `/gen/image`: 10 requests/minute per user
- `/gen/video`: 5 requests/minute per user

**Rate limit headers** (future):

```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1234567890
```

---

## Pagination

Feed endpoints support pagination:

**Request**:

```json
{
  "uid": "user-123",
  "feedType": "interest",
  "page": 1
}
```

**Response**:

```json
{
  "items": [...],
  "hasMore": true,
  "nextPage": 2
}
```

**Best Practices**:

- Start with `page: 1`
- Check `hasMore` before requesting next page
- Use `nextPage` value for next request
- Cache previous pages to avoid redundant requests

---

## Mock Mode

When `ENABLE_MOCKS=true` in backend `.env`:

- `/gen/image` and `/gen/video` return mock posts immediately
- No actual Vertex AI API calls are made
- Mock data is generated with random prompts
- Useful for development without API costs

**Mock response example**:

```json
{
  "jobId": "mock-uuid",
  "status": "ready",
  "etaMs": 0
}
```

The generated post will have:

- Mock media URLs (placeholder images/videos)
- Realistic metadata (timestamps, IDs, etc.)
- Consistent with real API responses

---

## OpenAPI / Swagger Docs

The backend automatically generates interactive API documentation:

**Interactive Docs**: <http://localhost:8000/docs>  
**ReDoc**: <http://localhost:8000/redoc>

These provide:

- All endpoints with request/response schemas
- Try-it-out functionality
- Model schemas
- Examples

---

## SDK / Client Libraries

### Python (Backend)

The backend uses FastAPI and Pydantic for type-safe API development.

### Dart / Flutter (Frontend)

The Flutter app uses Dio for HTTP requests:

```dart
import 'package:dio/dio.dart';

class MyWayApi {
  final Dio _dio;

  MyWayApi() : _dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: Env.apiConnectTimeout,
    receiveTimeout: Env.apiReceiveTimeout,
  ));

  Future<FeedResponse> getFeed({
    required String uid,
    required String feedType,
    required int page,
  }) async {
    final response = await _dio.post(
      '/feed',
      data: {
        'uid': uid,
        'feedType': feedType,
        'page': page,
      },
    );
    return FeedResponse.fromJson(response.data);
  }

  Future<GenResponse> generateImage({
    required String uid,
    required String prompt,
    String? aspect,
    int? seed,
  }) async {
    final response = await _dio.post(
      '/gen/image',
      data: {
        'uid': uid,
        'type': 'image',
        'prompt': prompt,
        if (aspect != null) 'aspect': aspect,
        if (seed != null) 'seed': seed,
      },
    );
    return GenResponse.fromJson(response.data);
  }
}
```

---

## Testing

### Using cURL

**Health check**:

```bash
curl http://localhost:8000/health
```

**Get feed**:

```bash
curl -X POST http://localhost:8000/feed \
  -H "Content-Type: application/json" \
  -d '{"uid":"test-user","feedType":"interest","page":1}'
```

**Generate image**:

```bash
curl -X POST http://localhost:8000/gen/image \
  -H "Content-Type: application/json" \
  -d '{"uid":"test-user","type":"image","prompt":"A peaceful forest"}'
```

### Using Postman

1. Import OpenAPI spec from <http://localhost:8000/openapi.json>
2. Create requests for each endpoint
3. Test with different parameters
4. Save as collection for team use

### Using Python

```python
import requests

# Health check
r = requests.get("http://localhost:8000/health")
print(r.json())

# Get feed
r = requests.post("http://localhost:8000/feed", json={
    "uid": "test-user",
    "feedType": "interest",
    "page": 1
})
print(r.json())

# Generate image
r = requests.post("http://localhost:8000/gen/image", json={
    "uid": "test-user",
    "type": "image",
    "prompt": "A serene lake"
})
print(r.json())
```

---

## Troubleshooting

### CORS Errors

If you get CORS errors in the browser:

- Backend allows all origins (`allow_origins=["*"]`)
- Check if backend is running
- Verify API base URL in frontend `.env`

### 500 Internal Server Error

Check backend logs for details:

```bash
# Backend terminal shows error details
ERROR:    Exception in ASGI application
```

Common causes:

- Missing environment variables (GCP project ID, etc.)
- Firebase/GCP not configured correctly
- Vertex AI API not enabled

### Slow Response Times

**In mock mode**: Should be instant (<100ms)

**In production mode**:

- Images: 2-5 seconds
- Videos (Fast): 6-20 seconds
- Videos (Slow): 30-60 seconds

If slower than expected:

- Check network connection
- Verify Vertex AI region (use same region as backend)
- Check GCP quota limits

---

## Future Enhancements

Planned API improvements:

- [ ] Authentication with Firebase ID tokens
- [ ] Rate limiting per user
- [ ] WebSocket support for real-time updates
- [ ] Batch generation endpoint
- [ ] Search endpoint
- [ ] User following/followers endpoints
- [ ] Like/comment endpoints
- [ ] Analytics endpoints
- [ ] Admin endpoints (moderation, etc.)

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-16
