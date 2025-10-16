# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

**Note**: This project is currently in active development. Once we reach v1.0, we will provide security support for stable versions.

---

## Reporting a Vulnerability

We take the security of Veo Social App seriously. If you discover a security vulnerability, please follow these steps:

### 🔒 Private Disclosure (Preferred)

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security vulnerabilities through one of these methods:

1. **GitHub Security Advisories** (Recommended):
   - Go to the [Security tab](../../security/advisories) of this repository
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email**:
   - Send details to the project maintainers
   - Include "SECURITY" in the subject line
   - We will respond within 48 hours

### What to Include

When reporting a vulnerability, please include:

- **Type of vulnerability** (e.g., XSS, SQL injection, authentication bypass)
- **Location** (file path, URL, or affected component)
- **Steps to reproduce** the vulnerability
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your contact information** for follow-up questions

### Example Report

```
Subject: SECURITY - Authentication Token Exposure in API Response

Description:
User authentication tokens are being exposed in API error responses,
potentially allowing attackers to hijack user sessions.

Location:
backend/src/main.py, line 145 - error handler

Steps to Reproduce:
1. Make API request to /api/posts without authentication
2. Observe error response includes 'debug_token' field
3. Use this token to authenticate as different user

Impact:
HIGH - Allows session hijacking and unauthorized access

Suggested Fix:
Remove debug fields from production error responses

Contact:
researcher@example.com
```

---

## Response Timeline

- **Initial Response**: Within 48 hours of report
- **Triage**: Within 1 week - we'll assess severity and validity
- **Fix Development**: Depends on complexity (typically 1-4 weeks)
- **Disclosure**: After fix is deployed and users have had time to update

### Severity Levels

We classify vulnerabilities using the following severity levels:

| Severity | Description | Response Time |
|----------|-------------|---------------|
| 🔴 **Critical** | Remote code execution, authentication bypass | 24-48 hours |
| 🟠 **High** | Data exposure, privilege escalation | 3-7 days |
| 🟡 **Medium** | XSS, CSRF, information disclosure | 1-2 weeks |
| 🟢 **Low** | Minor information leaks, non-exploitable bugs | 2-4 weeks |

---

## Security Best Practices for Users

### General Guidelines

1. **Keep Dependencies Updated**

   ```bash
   # Backend
   pip install --upgrade -r requirements.txt
   
   # Frontend
   flutter pub upgrade
   ```

2. **Use Environment Variables**
   - Never commit `.env` files
   - Never hardcode API keys or secrets
   - Use `.env.example` as templates only

3. **Firebase Security**
   - Enable App Check for production apps
   - Review Firestore and Storage rules regularly
   - Use custom claims for role-based access
   - Enable audit logging

4. **API Security**
   - Always use HTTPS in production
   - Implement rate limiting
   - Validate all user inputs
   - Sanitize outputs to prevent XSS

### Configuration Security

#### Backend `.env` File

```bash
# Good ✅
ENABLE_MOCKS=false
GCP_PROJECT_ID=your-project-id
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# Bad ❌
ENABLE_MOCKS=false
GCP_PROJECT_ID=mywayapp-473817  # Don't use example IDs
API_KEY=AIzaSy... # Never commit real keys
```

#### Frontend `.env` File

```bash
# Good ✅
API_BASE_URL=https://api.yourdomain.com
ENABLE_DEBUG_MODE=false

# Bad ❌
API_BASE_URL=http://192.168.1.140:8000  # Don't use local IPs
FIREBASE_API_KEY=AIzaSy...  # Never commit real keys
```

### Firestore Security Rules

Review and test your Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Ensure users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read, authenticated write
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

Test rules:

```bash
firebase emulators:start --only firestore
```

### Storage Security Rules

Protect user uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Only allow authenticated uploads
    match /posts/{postId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.resource.size < 100 * 1024 * 1024  // 100MB max
                   && request.resource.contentType.matches('image/.*|video/.*');
    }
  }
}
```

---

## Known Security Considerations

### API Costs

This application uses **paid Google Cloud APIs** (Vertex AI):

- **Veo 3.1**: ~$0.065-$0.13 per video generation
- **Imagen 4.0**: ~$0.02 per image generation

**Mitigation Strategies**:

1. **Rate Limiting** (implemented in backend)
   - 10 videos per user per day
   - 30 images per user per day

2. **Usage Quotas** (configurable in `.env`)

   ```bash
   MAX_VIDEO_PER_USER_PER_DAY=10
   MAX_IMAGE_PER_USER_PER_DAY=30
   ```

3. **Cost Alerts** (recommended for production)
   - Set up budget alerts in Google Cloud Console
   - Monitor usage with Cloud Billing API

### Authentication

- Uses **Firebase Authentication**
- Supports email/password authentication
- Tokens expire after 1 hour (configurable)
- Refresh tokens handled automatically

**Recommendations**:

- Enable **2FA** for admin accounts
- Implement **email verification** for new users
- Use **reCAPTCHA** for sign-up forms
- Monitor for **unusual login patterns**

### Data Privacy

This app stores:

- User profiles (email, display name)
- User-generated content (posts, images, videos)
- Usage statistics (for rate limiting)

**Compliance**:

- Follow **GDPR** if serving EU users
- Implement **data deletion** requests
- Provide **privacy policy** and **terms of service**
- Use **anonymized analytics**

---

## Security Features Implemented

### Backend Security

- ✅ **CORS Protection**: Configured origins in FastAPI
- ✅ **Input Validation**: Pydantic models for all requests
- ✅ **Rate Limiting**: Per-user and global limits
- ✅ **Error Handling**: No sensitive data in error responses
- ✅ **Environment-based Config**: No hardcoded secrets
- ✅ **Firebase Admin SDK**: Server-side token verification

### Frontend Security

- ✅ **Firebase Auth**: Secure authentication flow
- ✅ **Token Management**: Automatic refresh and expiry
- ✅ **Input Sanitization**: XSS prevention in user content
- ✅ **HTTPS Only**: Production builds enforce HTTPS
- ✅ **Environment Config**: API URLs from environment variables

### Infrastructure Security

- ✅ **Firestore Rules**: User-scoped data access
- ✅ **Storage Rules**: Authenticated uploads only
- ✅ **API Keys**: Never committed to repository
- ✅ **Service Accounts**: Minimal required permissions
- ✅ **Secrets Management**: Environment variables and secret managers

---

## Security Checklist for Deployment

Before deploying to production, ensure:

### Backend

- [ ] `ENABLE_MOCKS=false` in production `.env`
- [ ] CORS origins configured to your frontend domain
- [ ] Rate limiting enabled and tested
- [ ] Firebase Admin SDK credentials properly configured
- [ ] Error responses don't leak sensitive information
- [ ] Logging excludes sensitive data (tokens, API keys)
- [ ] HTTPS enforced (via Cloud Run or load balancer)

### Frontend

- [ ] `API_BASE_URL` points to production backend
- [ ] Firebase configuration uses production project
- [ ] Debug mode disabled (`flutter build --release`)
- [ ] App Check enabled for production
- [ ] Analytics anonymized (if applicable)
- [ ] Privacy policy and terms linked in app

### Infrastructure

- [ ] Firestore rules tested and deployed
- [ ] Storage rules tested and deployed
- [ ] Budget alerts configured in GCP
- [ ] Service account has minimal permissions
- [ ] Audit logging enabled
- [ ] Backups configured (Firestore, Storage)

---

## Regular Security Maintenance

### Monthly

- [ ] Review access logs for suspicious activity
- [ ] Check for new security advisories for dependencies
- [ ] Review and update Firestore/Storage rules if needed
- [ ] Monitor API usage and costs

### Quarterly

- [ ] Update all dependencies to latest stable versions
- [ ] Review and rotate service account keys
- [ ] Audit user permissions and roles
- [ ] Conduct security review of new features

### Annually

- [ ] Comprehensive security audit
- [ ] Penetration testing (if resources allow)
- [ ] Review and update security policies
- [ ] Update privacy policy and terms of service

---

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)
- [Flutter Security](https://docs.flutter.dev/deployment/security)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

---

## Questions?

If you have questions about security that don't require private disclosure, you can:

- Open a **GitHub Discussion**
- Create an issue with the `security` label
- Check existing security-related issues

For sensitive security matters, always use the private disclosure methods described at the top of this document.

---

Thank you for helping keep Veo Social App secure! 🔒
