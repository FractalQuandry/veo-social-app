# Cost Guide - Veo Social App

⚠️ **CRITICAL**: Running this app in production mode **WILL COST MONEY**. This guide explains the costs and how to minimize them.

---

## TL;DR - Cost Summary

| Service | Unit Cost | Example Usage | Monthly Cost |
|---------|-----------|---------------|--------------|
| **Veo 3.1 (Fast)** | $0.065/video | 100 videos | $6.50 |
| **Veo 3.1 (Slow)** | $0.13/video | 100 videos | $13.00 |
| **Imagen 4.0** | $0.02/image | 500 images | $10.00 |
| **Gemini Flash** | $0.0001/prompt | 1000 prompts | $0.10 |
| **Firestore** | See below | Light usage | $1-5 |
| **Cloud Storage** | $0.02/GB | 10 GB | $0.20 |
| **Firebase Hosting** | Free | Static site | $0 |

**Realistic Monthly Cost for Personal Use**: $10-30  
**Realistic Monthly Cost with 100 Users**: $100-500  
**Realistic Monthly Cost with 1000 Users**: $1,000-5,000+

---

## Google Cloud Platform (GCP) Costs

### 1. Vertex AI - Veo 3.1 (Video Generation)

**Pricing** (as of January 2025):

- **Fast Mode**: ~$0.065 per video
- **Slow Mode**: ~$0.13 per video

**What affects cost**:

- Video length (5s, 10s videos cost same as base rate)
- Quality mode (Fast vs Slow)
- Number of reference images (no extra cost, but up to 3)

**Example scenarios**:

```
Personal Use (10 videos/day):
  10 videos/day × 30 days × $0.065 = $19.50/month

Moderate Use (50 videos/day):
  50 videos/day × 30 days × $0.065 = $97.50/month

Heavy Use (200 videos/day):
  200 videos/day × 30 days × $0.065 = $390/month
```

**Cost optimization**:

- Use Fast mode for drafts (2-3x faster, 50% cheaper)
- Use Slow mode only for final versions
- Implement daily generation limits per user
- Cache and reuse generated content when possible

### 2. Vertex AI - Imagen 4.0 (Image Generation)

**Pricing**:

- **Standard**: ~$0.02 per image

**What affects cost**:

- Number of images generated
- Reference images (no extra cost)

**Example scenarios**:

```
Personal Use (20 images/day):
  20 images/day × 30 days × $0.02 = $12/month

Moderate Use (100 images/day):
  100 images/day × 30 days × $0.02 = $60/month

Heavy Use (500 images/day):
  500 images/day × 30 days × $0.02 = $300/month
```

**Cost optimization**:

- Images are much cheaper than videos - use when possible
- Generate thumbnails/previews as images before full videos
- Implement user quotas (e.g., 10 free images/day)

### 3. Vertex AI - Gemini Flash (Prompt Enhancement)

**Pricing**:

- **Input**: ~$0.0001 per 1000 characters
- **Output**: ~$0.0003 per 1000 characters

**What affects cost**:

- Length of user prompts
- Length of enhanced prompts

**Example scenarios**:

```
1000 prompts/month (avg 100 chars each):
  1000 × 0.1k chars × $0.0001 = $0.01/month

10,000 prompts/month:
  10,000 × 0.1k chars × $0.0001 = $0.10/month
```

**Cost optimization**:

- Gemini is very cheap - don't worry about it
- Can disable prompt enhancement to save negligible costs
- Consider caching enhanced prompts for common themes

---

## Firebase Costs

### 4. Cloud Firestore (Database)

**Pricing**:

- **Reads**: $0.06 per 100,000 reads
- **Writes**: $0.18 per 100,000 writes
- **Deletes**: $0.02 per 100,000 deletes
- **Storage**: $0.18 per GB/month

**Free tier** (Spark Plan):

- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day
- 1 GB storage

**What affects cost**:

- Number of feed refreshes (reads)
- Number of posts created (writes)
- Feed size (more posts = more reads)
- Profile updates (writes)

**Example scenarios**:

```
Personal Use (within free tier):
  Daily: 100 reads, 10 writes
  Monthly: 3,000 reads, 300 writes = $0

Small App (10 users):
  Daily: 1,000 reads, 100 writes
  Monthly: 30,000 reads, 3,000 writes = $0.02 + $0.01 = $0.03

Medium App (100 users):
  Daily: 10,000 reads, 1,000 writes
  Monthly: 300,000 reads, 30,000 writes = $0.18 + $0.05 = $0.23

Large App (1000 users):
  Daily: 100,000 reads, 10,000 writes
  Monthly: 3M reads, 300k writes = $1.80 + $0.54 = $2.34
```

**Cost optimization**:

- Use pagination (load 50 posts at a time, not all)
- Cache feed data in app memory
- Batch writes when possible
- Use Firestore offline persistence (reduces reads)
- Limit feed auto-refresh frequency

### 5. Firebase Storage (Cloud Storage)

**Pricing**:

- **Storage**: $0.026 per GB/month
- **Downloads**: $0.12 per GB
- **Uploads**: Free

**Free tier** (Spark Plan):

- 5 GB storage
- 1 GB downloads/day

**What affects cost**:

- Number of generated videos (videos are large)
- Number of images
- User downloads/views

**Example scenarios**:

```
Personal Use (10 videos, 50 images):
  Storage: 10 × 5MB + 50 × 1MB = 100MB = $0.002/month
  Downloads: 100MB × 30 views = 3GB = $0.36/month

Small App (100 videos, 500 images):
  Storage: 100 × 5MB + 500 × 1MB = 1GB = $0.026/month
  Downloads: 1GB × 30 views/video = 30GB = $3.60/month

Medium App (1000 videos, 5000 images):
  Storage: 1000 × 5MB + 5000 × 1MB = 10GB = $0.26/month
  Downloads: 10GB × 30 views = 300GB = $36/month
```

**Cost optimization**:

- Use Firebase CDN (downloads are free via CDN in some regions)
- Compress videos to reasonable quality (1080p @ 30fps is plenty)
- Use 9:16 aspect ratio (smaller file size than 16:9)
- Implement view limits (e.g., 8 free views, then paywall)
- Delete old unused content

### 6. Firebase Authentication

**Pricing**:

- **Free** for email/password, anonymous, Google, etc.
- Phone auth: $0.01 per verification (not used in this app)

**Cost**: $0 (unless using phone auth)

### 7. Firebase Hosting

**Pricing**:

- **Free tier**: 10 GB storage, 360 MB/day bandwidth
- **Paid**: $0.026 per GB storage, $0.15 per GB bandwidth

**What you host**:

- Flutter web app (static files)

**Cost optimization**:

- Hosting is free for most use cases
- Use Firebase CDN for optimal performance

---

## Total Cost Examples

### Scenario 1: Solo Developer (You)

**Usage**:

- 5 videos/day (Fast mode)
- 10 images/day
- 20 feed refreshes/day

**Monthly costs**:

```
Veo 3.1:     5 × 30 × $0.065 = $9.75
Imagen 4.0:  10 × 30 × $0.02 = $6.00
Gemini:      ~$0.05
Firestore:   Free tier (within limits)
Storage:     ~$0.50
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL:       ~$16.30/month
```

### Scenario 2: Small Community (10 active users)

**Usage per user**:

- 3 videos/day
- 5 images/day
- 50 feed refreshes/day

**Monthly costs**:

```
Veo 3.1:     3 × 10 × 30 × $0.065 = $58.50
Imagen 4.0:  5 × 10 × 30 × $0.02 = $30.00
Gemini:      ~$0.50
Firestore:   ~$2.00
Storage:     ~$5.00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL:       ~$96/month
```

### Scenario 3: Growing App (100 active users)

**Usage per user**:

- 2 videos/day
- 3 images/day
- 30 feed refreshes/day

**Monthly costs**:

```
Veo 3.1:     2 × 100 × 30 × $0.065 = $390
Imagen 4.0:  3 × 100 × 30 × $0.02 = $180
Gemini:      ~$5
Firestore:   ~$20
Storage:     ~$50
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL:       ~$645/month
```

### Scenario 4: Popular App (1000 active users)

**Usage per user**:

- 1 video/day
- 2 images/day
- 20 feed refreshes/day

**Monthly costs**:

```
Veo 3.1:     1 × 1000 × 30 × $0.065 = $1,950
Imagen 4.0:  2 × 1000 × 30 × $0.02 = $1,200
Gemini:      ~$50
Firestore:   ~$200
Storage:     ~$500
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL:       ~$3,900/month
```

---

## Cost Optimization Strategies

### 1. Use Mock Mode During Development

```bash
# In backend/.env
ENABLE_MOCKS=true
```

This disables all Vertex AI calls and uses fake data. **Always develop with mocks enabled**.

### 2. Implement Usage Quotas

In backend `.env`:

```bash
MAX_FREE_VIEWS=8        # Limit free video views per user
MAX_FREE_DEPTH=2        # Limit "More Like This" depth
```

In your app:

- Limit generations per user per day (e.g., 5 images, 2 videos)
- Show warnings when approaching limits
- Require payment/subscription for heavy users

### 3. Cache Aggressively

**Backend**:

- Cache trending topics in memory (regenerate every hour)
- Cache fallback posts (reuse mock content)
- Use Firestore offline persistence

**Frontend**:

- Use `cached_network_image` for image caching
- Cache feed data in app memory
- Preload only next 2-3 videos in feed

### 4. Optimize Generation Settings

**Use Fast mode by default**:

```dart
// In Flutter app
final speed = "fast";  // vs "slow"
```

**Use images instead of videos**:

- Images are 3-6x cheaper than videos
- Generate image previews before full videos
- Let users choose media type

### 5. Set Up Budget Alerts

In Google Cloud Console:

1. Go to **Billing** → **Budgets & alerts**
2. Click **Create Budget**
3. Set monthly budget (e.g., $50)
4. Set alert thresholds:
   - 50% of budget
   - 90% of budget
   - 100% of budget
5. Add email notifications

### 6. Monitor Costs Regularly

**In GCP Console**:

- Go to **Billing** → **Reports**
- View costs by service
- Identify expensive users/operations
- Set up custom dashboards

**In Firebase Console**:

- Check **Usage** tab for each service
- Monitor approaching quota limits

### 7. Implement Rate Limiting

**In backend**:

```python
# Limit generations per user per minute
from slowapi import Limiter

limiter = Limiter(key_func=get_user_id)

@app.post("/gen/video")
@limiter.limit("5/minute")  # Max 5 videos/minute per user
def gen_video(req: GenRequest):
    ...
```

### 8. Delete Old Content

Implement a cleanup job:

- Delete posts older than 30 days
- Delete unused reference images
- Archive popular content instead of deleting

### 9. Use Lower Quality Settings

**Videos**:

- 720p instead of 1080p (saves storage and bandwidth)
- 30fps instead of 60fps
- 9:16 aspect ratio (smaller than 16:9)

**Images**:

- 1024x1024 instead of 2048x2048
- JPEG with 80% quality instead of PNG

### 10. Consider Monetization

If your app grows, consider:

- **Freemium model**: Free tier (limited), paid tier (unlimited)
- **Ads**: Show ads between posts (AdMob)
- **Subscriptions**: $5/month for unlimited generations
- **Pay-per-use**: $1 for 10 videos

**Break-even analysis**:

```
If cost per user = $3/month
Need to charge at least $5/month to profit
At 100 paid users: $500 revenue - $300 costs = $200 profit
```

---

## Free Tier Limits

### GCP Free Tier (First 90 days)

- $300 credit for new users
- Covers ~4,600 videos or 15,000 images
- No credit card required initially

After free tier:

- Must enable billing to continue
- Costs apply immediately

### Firebase Free Tier (Spark Plan)

**Firestore**:

- 50,000 reads/day
- 20,000 writes/day
- 1 GB storage

**Storage**:

- 5 GB storage
- 1 GB downloads/day

**Hosting**:

- 10 GB storage
- 360 MB/day bandwidth

**Good for**:

- Personal projects
- Small communities (<10 users)
- Testing and development

---

## Cost Comparison: Mock vs Real

| Mode | Monthly Cost | When to Use |
|------|--------------|-------------|
| **Mock** | $0 | Development, testing, demos |
| **Real (Personal)** | $10-30 | Personal use, portfolio projects |
| **Real (Small App)** | $50-200 | <50 users, hobby project |
| **Real (Growing App)** | $200-1000 | 50-500 users, side business |
| **Real (Popular App)** | $1000+ | 500+ users, requires monetization |

---

## Recommendations

### For Developers/Learning

✅ **Use mock mode exclusively**

- No costs, instant results
- Perfect for learning and experimenting
- Can build entire app without GCP account

### For Personal Use

✅ **Enable real APIs, set strict quotas**

- Set MAX_FREE_VIEWS=8, MAX_FREE_DEPTH=2
- Generate 5 images + 2 videos per day max
- Expected cost: $10-20/month

### For Side Project/Portfolio

⚠️ **Start with mock mode, enable APIs selectively**

- Use real APIs for demo videos only
- Keep mock mode for daily development
- Budget: $20-50/month

### For Production/Startup

⚠️ **Requires careful cost management**

- Implement monetization from day 1
- Set up comprehensive monitoring
- Budget: Variable, plan for $500-5000/month

---

## Additional Resources

- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing)
- [Firestore Pricing](https://firebase.google.com/docs/firestore/quotas)
- [GCP Free Tier](https://cloud.google.com/free)

---

**Remember**: The best way to control costs is to **use mock mode** during development and **set strict quotas** in production! 💰

**Document Version**: 1.0  
**Last Updated**: 2025-01-16
