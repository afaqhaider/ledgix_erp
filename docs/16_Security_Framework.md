# 16 Security Framework

## Authentication
- Primary: Firebase Authentication (Email/Password, Google).
- Multi-Factor Authentication (MFA) required for high-privilege roles.
- Password Policy: Min 12 characters, mix of upper/lower/symbols/numbers.

## Authorization
- **Role-Based Access Control (RBAC):** Permissions assigned to roles, roles assigned to users per company.
- **Firestore Security Rules:** Server-side enforcement of access.
  - *Example:* `allow read: if request.auth.uid in get(/databases/$(database)/documents/companies/$(companyId)).data.users;`

## Data Isolation (Multi-Tenancy)
- Every document contains a `company_id`.
- Queries must always filter by `company_id`.
- Tenant isolation is enforced at the database level via security rules.

## Encryption
- **In-Transit:** Mandatory HTTPS (TLS 1.2+).
- **At-Rest:** Firebase/GCP managed disk encryption. Sensitive custom fields (like tax IDs) can be application-level encrypted.

## Session Handling
- Tokens expire after 1 hour (Firebase default).
- Refresh tokens handled securely by Flutter Firebase SDK.
- Revocation of sessions on password change or remote logout.

## Audit Logging
- Every write operation triggers a record in `audit_logs`.
- Logs include: `timestamp`, `user_id`, `action_type`, `document_id`, `old_values`, `new_values`.
- Audit logs are immutable (read-only for all except system processes).
