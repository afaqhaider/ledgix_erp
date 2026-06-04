# 05 Non-Functional Requirements

## Performance
- **Dashboard Load:** Initial dashboard metrics must load under 2 seconds.
- **Report Generation:** Standard reports (P&L, Balance Sheet) should generate in under 5 seconds for 10k transactions.
- **Search:** Global search results should appear in under 500ms.

## Availability & Reliability
- **Uptime:** Target 99.9% availability.
- **Auto-Save:** Drafts should be saved frequently to prevent data loss.
- **Offline Mode:** Limited read-only access to cached data when offline.

## Security
- **Data Encryption:** TLS 1.3 for data in transit; AES-256 for data at rest (managed by Firebase).
- **Authentication:** Mandatory MFA for 'Owner' and 'Admin' roles.
- **Session Management:** Automatic logout after 30 minutes of inactivity.

## Scalability
- **Horizontal Scaling:** System must support thousands of simultaneous tenants via Firebase's multi-tenant infrastructure.
- **Concurrency:** Optimistic locking for inventory and document updates.

## Auditability
- **Immutable Logs:** Every document save must create an entry in the `audit_logs` collection.
- **User Tracking:** Store `created_by`, `updated_by`, and `timestamp` on every record.

## Backup & Recovery
- **Daily Backups:** Automated Firestore backups.
- **Point-in-Time Recovery:** Ability to restore data to a specific state (via Firebase backups).

## UI/UX & Accessibility
- **Responsive:** UI must adapt from 320px (Mobile) to 4K (Desktop).
- **Accessibility:** WCAG 2.1 Level AA compliance.
- **Localization:** Support for RTL languages (Arabic, Urdu) and multiple date/number formats.
