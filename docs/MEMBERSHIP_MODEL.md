# Canonical Membership Model

The `companies/{companyId}/members/{uid}` document is the source of truth for authorization.

## Fields Specification

| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | string | Firebase Auth UID |
| `email` | string | User email (for lookup/invite) |
| `displayName` | string | Full name within the company |
| `role` | enum | Functional role (see Roles list) |
| `status` | enum | `invited`, `active`, `disabled` |
| `userType` | enum | `internal`, `customerPortal`, `supplierPortal` |
| `customerId` | string? | Link to `customers` collection if `userType` is `customerPortal` |
| `supplierId` | string? | Link to `suppliers` collection if `userType` is `supplierPortal` |
| `permissions` | list | Granular permission strings |
| `createdAt` | timestamp | Member creation date |
| `updatedAt` | timestamp | Last update date |

## Roles
- `superAdmin`: Full system access (Internal only).
- `owner`: Full company access.
- `admin`: Full operational access.
- `accountant`: Financial operations.
- `cashier`: Payments and receipts.
- `sales`: Quotations and Invoices.
- `purchase`: POs and Bills.
- `storekeeper`: Inventory and Items.
- `hr`: Payroll and Employees.
- `employee`: Limited personal/operational access.
- `customerPortal`: Restricted to customer-specific views.
- `supplierPortal`: Restricted to supplier-specific views.
