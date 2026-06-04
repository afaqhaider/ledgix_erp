# 03 Business Requirements

## Introduction
This document outlines the high-level business requirements for each module in LedGix ERP. Each module must align with the core principles of simplicity, accuracy, and auditability.

## Core Modules

### 1. Dashboard
- **Purpose:** Provide a real-time overview of the business health.
- **Features:** Cash balance, Sales trends, AR/AP aging, Recent transactions.

### 2. Companies & Branches
- **Purpose:** Support multi-entity and multi-location operations.
- **Business Rules:** A user can belong to multiple companies; a company can have multiple branches.

### 3. Users & Permissions
- **Purpose:** Manage access and security.
- **Features:** Role-based access control (RBAC), Invite system.

### 4. Accounting (Core)
- **Purpose:** The "Engine" of the ERP.
- **Features:** Chart of Accounts, Journal Entries, Ledger, Financial Statements.
- **Business Rules:** Double-entry must balance. No deletion of posted entries (only reversals).

### 5. Customers & Suppliers
- **Purpose:** Relationship management.
- **Features:** Master data, opening balances, credit limits.

### 6. Sales & Purchase
- **Purpose:** Revenue and Expense tracking.
- **Features:** Quotations, Orders, Invoices, Bills.

### 7. Inventory
- **Purpose:** Stock management.
- **Features:** Multiple warehouses, stock adjustments, transfers.

### 8. HR & Payroll
- **Purpose:** Employee lifecycle and payment.
- **Features:** Attendance, salary structures, payslips.

### 9. Manufacturing
- **Purpose:** Production tracking.
- **Features:** Bill of Materials (BOM), Work Orders, Production Costing.

---

## Detailed Module Specification Template
For every module, the following must be defined:

| Section | Description |
| :--- | :--- |
| **Purpose** | What problem does this module solve? |
| **Features** | List of specific functionalities. |
| **Business Rules** | Logic constraints (e.g., "Cannot sell below cost"). |
| **User Stories** | "As a [role], I want to [action] so that [benefit]." |
| **Acceptance Criteria** | Requirements for a feature to be considered complete. |
