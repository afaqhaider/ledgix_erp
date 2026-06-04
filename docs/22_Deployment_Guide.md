# 22 Deployment Guide

## Environments
1. **Development (`dev`):** Sandbox for developers.
2. **Testing/QA (`test`):** Stable build for internal testing.
3. **Staging (`stage`):** Pre-production environment with production-like data.
4. **Production (`prod`):** Live customer environment.

## Firebase Deployment
- **Firestore Rules:** `firebase deploy --only firestore:rules`
- **Cloud Functions:** `firebase deploy --only functions`
- **Hosting (Web):** `firebase deploy --only hosting`

## Version Management
- Use Semantic Versioning (`MAJOR.MINOR.PATCH`).
- Flutter `pubspec.yaml` version must be updated for every release.

## Environment Management
- Use `--dart-define` or `.env` files for environment-specific variables (API keys, project IDs).
- **Never commit production secrets to Git.**

## Rollback Procedures
1. **Frontend:** Re-deploy previous version via Firebase Hosting history.
2. **Functions:** Re-deploy previous tagged version of functions code.
3. **Database:** (Critical) Use scheduled backups to restore state if a migration fails.

## CI/CD Pipeline
- **Triggers:** Push to `main` (Dev), Tag `v*` (Prod).
- **Steps:**
  1. Static analysis (`flutter analyze`).
  2. Run tests (`flutter test`).
  3. Build artifacts (Web/APK/IPA).
  4. Deploy to Firebase.
