# LedGix ERP Architecture

## SaaS Multi-Tenant Foundation
LedGix ERP is designed as a multi-tenant SaaS platform. The core principle is strict data isolation between companies (tenants).

### Core Components
1. **Multi-Tenancy:** Each company has its own isolated data silo within Firestore.
2. **Membership Model:** Users are linked to companies via a explicit membership record.
3. **Role-Based Access Control (RBAC):** Permissions are defined at the membership level, not the global user level.
4. **Security-First:** Data access is enforced at the database level using Firestore Security Rules.

### Data Isolation
All business data resides under the `companies/{companyId}` path. 
Example: `companies/{companyId}/salesInvoices/{invoiceId}`

### Identity & Access
- **Global User Profile:** `users/{uid}` stores basic info (email, name, default company).
- **Company Membership:** `companies/{companyId}/members/{uid}` defines the user's role and permissions within that specific company.

### Backend Evolution
While current operations are client-side, critical business logic (numbering, posting, audits) is designated for future migration to Firebase Cloud Functions for enhanced integrity.
