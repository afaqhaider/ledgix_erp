# 09 User Roles & Permissions

## Roles Definition
- **Super Admin:** Global system access (LedGix Team).
- **Owner:** Full access to all company data and settings.
- **General Manager:** High-level access, excluding sensitive HR/Payroll settings.
- **Accountant:** Full financial access (JE, Reports, Closing).
- **Cashier:** Restricted to payments, receipts, and POS.
- **Sales:** Can create quotes and invoices.
- **Purchase:** Can create POs and Bills.
- **Storekeeper:** Inventory movements and GRNs.
- **HR:** Employee management and payroll.
- **Employee:** Self-service access (View payslips, Request leave).

## Permission Matrix

| Module | Super Admin | Owner | Accountant | Sales | Storekeeper |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Settings** | Full | Full | View | - | - |
| **CoA** | Full | Full | Full | - | - |
| **Journal Entries** | Full | Full | Full | - | - |
| **Sales Invoice** | Full | Full | Full | Create/Edit | - |
| **Purchase Bill** | Full | Full | Full | - | - |
| **Inventory** | Full | Full | Full | View | Full |
| **Financial Reports**| Full | Full | Full | - | - |

## Permissions Detail
- **View:** Read access to records.
- **Create:** Ability to initiate a new record (Draft).
- **Edit:** Modify existing draft records.
- **Delete:** Remove draft records.
- **Approve:** Verify correctness (e.g., Manager Approval).
- **Post:** Commit to General Ledger (Immutability starts here).
- **Export:** Download data as PDF/Excel.

## Tenant Isolation
- Permissions are strictly scoped to the `company_id`.
- Cross-company data leakage is prevented via Firestore Security Rules.
