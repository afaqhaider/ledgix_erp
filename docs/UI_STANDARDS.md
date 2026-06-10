# LedGix ERP - UI Standards

This document defines the mandatory laws for building User Interfaces in LedGix ERP.

## 1. Page Architecture

All voucher listing pages (Invoices, Bills, Payments, etc.) MUST use the `VoucherListPage` component or follow its exact structure.

### Required Elements per Page:
1.  **PageHeader**: Title and "Add New" button.
2.  **FilterBar**: Search field, Date range picker, and Status filters.
3.  **ERPDataTable**: Standardized table with:
    - Formatted Dates
    - Formatted Amounts (Right-aligned)
    - Status Badges
    - Standard Action Menu (View, Edit, Delete)

## 2. Shared Components

Do not create local versions of these components:
- `ERPPageHeader`
- `ERPActionToolbar`
- `ERPDataTable`
- `ERPStatusBadge`
- `ERPEmptyState`
- `ERPConfirmDeleteDialog`

## 3. Typography & Spacing

- Use `AppTheme` exclusively.
- No hardcoded `Colors.blue` or `padding: EdgeInsets.all(10)`.
- Use standard spacing constants (e.g., `ErpSpacing.m`).

## 4. Voucher Actions

Every voucher entry in a list MUST provide:
- **View**: Navigates to details or opens a read-only pane.
- **Edit**: Navigates to edit screen or opens an edit pane.
- **Delete**: Triggers a `ERPConfirmDeleteDialog`.

## 5. Roles & Permissions (Current Phase)

**Law**: Currently, role restrictions are lifted for UI development. All users see Add, Edit, and Delete actions. RBAC will be re-applied centrally at a later stage.
