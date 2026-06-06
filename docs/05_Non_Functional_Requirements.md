# 05 Non-Functional Requirements

## 1. Performance
- **Response Time:**
    - Dashboard and core list views must load in under 2 seconds on standard 4G/Broadband.
    - Financial reports (Balance Sheet, P&L) for a standard SME (up to 10k transactions/year) must generate in under 5 seconds.
    - UI interactions (button clicks, tab switching) must feel instantaneous (< 200ms).
- **Concurrency:**
    - Support at least 1,000 concurrent users per region in the initial Firebase phase.

## 2. Availability & Reliability
- **Uptime:** Target 99.9% availability for the production environment.
- **Offline Capability:**
    - Mobile apps should allow viewing cached data.
    - Critical data entry (Sales Invoice) should have basic offline support with sync-on-reconnect.
- **Data Integrity:**
    - Zero data loss guarantee for posted transactions.
    - Transactional writes for all multi-document updates (e.g., Invoice + Journal Entry + Stock update).

## 3. Scalability
- **Vertical & Horizontal:**
    - Leverage Firebase's auto-scaling for the first 50,000 companies.
    - Architecture must allow migration to PostgreSQL/Microservices without rewriting business logic.
- **Media Storage:**
    - Use Firebase Storage with CDN for fast document/image retrieval.

## 4. Security
- **Data Isolation:** Strict multi-tenant architecture. One company cannot access another's data under any circumstances.
- **Authentication:**
    - Firebase Auth for secure identity management.
    - Support for MFA (Multi-Factor Authentication) for Owner and Admin roles.
- **Encryption:**
    - Data in transit: SSL/TLS (HTTPS).
    - Data at rest: AES-256 (Firebase default).
- **Password Policy:** Minimum 8 characters, mix of alphanumeric and special characters.

## 5. Auditability
- **Change Logs:** Track who created/edited every document and when.
- **Immutability:** Posted financial entries cannot be modified. Errors must be corrected via "Reversal" or "Adjustment" entries.
- **System Logs:** Capture critical system errors and security events.

## 6. Usability & Accessibility
- **Responsive Design:** Consistent experience across Desktop Web, Tablets, and Mobile phones.
- **Localization:**
    - Initial support for English.
    - Framework must support RTL (Arabic/Urdu) for future expansion.
    - Number formatting (1,000.00) and date formatting (DD-MMM-YYYY) must be consistent.
- **Theme:** Default "Pure Black" (#000000) dark mode to reduce eye strain.

## 7. Compliance
- **Accounting:** Alignment with IFRS (International Financial Reporting Standards).
- **Tax:** Support for VAT/GST calculations and reporting.
- **GDPR:** Support for data deletion requests and privacy requirements.

## 8. Backup & Disaster Recovery
- **Backups:** Daily automated backups of Firestore data.
- **Recovery Time Objective (RTO):** Under 4 hours for major system failures.
- **Recovery Point Objective (RPO):** Under 24 hours.
