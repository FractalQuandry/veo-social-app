# Infrastructure

Infrastructure configuration and deployment files.

## Contents

- **firestore.rules** - Firestore security rules
- **storage.rules** - Firebase Storage security rules
- **firestore.indexes.json** - Firestore index definitions

## Deployment

### Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Storage Rules

```bash
firebase deploy --only storage
```

### Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

## Security Rules

The included rules provide:
- User authentication checks
- Private/public content access control
- Read/write permissions based on ownership
- Media upload restrictions

## Customization

Edit rules based on your security requirements. Test rules in Firebase Console before deploying to production.
