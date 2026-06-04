# 23 Release Management

## Process
1. **Feature Freeze:** No new features allowed for the current release cycle.
2. **Regression Testing:** Full sweep of the testing checklist.
3. **Change Log Update:** Document all changes in `CHANGELOG.md`.
4. **Approval:** Final sign-off from QA Lead and Product Owner.
5. **Deployment:** Follow the [Deployment Guide](22_Deployment_Guide.md).
6. **Post-Release Monitoring:** Check Error logs (Sentry/Crashlytics) for spikes.

## Versioning Strategy
- **Major:** Breaking changes or massive new modules (e.g., HR/Manufacturing).
- **Minor:** New features, UI overhauls.
- **Patch:** Bug fixes and performance improvements.

## Hotfix Process
1. Branch from `main` or latest release tag.
2. Apply fix and unit test.
3. Deploy to Staging first.
4. Fast-track to Production.
5. Merge back into development branches.

## Release Communication
- Internal: Slack/Teams update.
- External: "What's New" pop-up in-app and email newsletter.
