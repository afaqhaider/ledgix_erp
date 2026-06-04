# 21 Testing Framework

## Strategy
- **Unit Tests:** For business logic, formatters, and models. (Target: 80%+ coverage).
- **Widget Tests:** For reusable UI components and form validation.
- **Integration Tests:** For end-to-end flows (e.g., Create Quote → Convert to Invoice → Post).
- **UAT (User Acceptance Testing):** Manual testing by the functional team/accountants.

## Specialized Testing
- **Accounting Accuracy:** Specialized test suite to verify debits equal credits for all transaction types.
- **Concurrency Testing:** Verifying that multiple users editing the same stock item don't cause inconsistency.
- **Security Testing:** Pentesting for Firestore rules and API endpoints.

## Testing Checklist Template
- [ ] Happy path works as expected.
- [ ] Edge cases (zero amounts, max string lengths) handled.
- [ ] Error messages are user-friendly.
- [ ] Audit log entry created.
- [ ] Financial balances updated correctly.
- [ ] Permissions respected (Unauthorized user can't access).
- [ ] Responsive design check (Mobile vs Desktop).

## Tools
- `flutter_test` for Unit/Widget tests.
- `integration_test` package.
- `firebase_emulator` for local backend testing.
