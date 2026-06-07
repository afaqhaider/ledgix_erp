# Security Rules Logic

## Firestore Rules

### General Principles
- `read/write` is denied by default.
- Users must be authenticated (`request.auth != null`).
- Access to `companies/{companyId}/**` requires a valid membership in `companies/{companyId}/members/{uid}`.
- Membership must have `status == 'active'`.

### Member Validation
A helper function `isMember(companyId)` checks:
`get(/databases/$(database)/documents/companies/$(companyId)/members/$(request.auth.uid)).data.status == 'active'`

### Data Integrity
- Every document in a subcollection of `companies/{companyId}` should optionally contain a `companyId` field that MUST match the parent `companyId` in the path.

### Portal Restrictions
- `customerPortal` users can only access their own documents (where `customerId` matches their membership `customerId`).
- `supplierPortal` users can only access their own documents (where `supplierId` matches their membership `supplierId`).

## Storage Rules
- `companies/{companyId}/branding/**` is readable by all active members.
- `companies/{companyId}/documents/**` is restricted based on user role and portal status.
- Users cannot access `companies/{otherCompanyId}/**`.
