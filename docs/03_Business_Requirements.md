# 03 Business Requirements

## 1. Introduction
This document outlines the high-level business requirements for LedGix ERP. The platform is designed to provide a comprehensive, integrated solution for SMEs across various sectors (Trading, Service, Manufacturing, Construction).

## 2. General Requirements
- **Multi-Company Support:** Ability to manage multiple legal entities under one account.
- **Multi-Branch Support:** Support for multiple locations with independent or consolidated reporting.
- **Multi-Currency:** Support for international transactions with exchange rate management.
- **Auditability:** Every transaction must leave an audit trail. Deletions are generally not allowed for posted documents; reversals must be used.
- **Scalability:** System must handle increasing data volumes and user counts without performance degradation.

## 3. Module Requirements

### 3.1 Dashboard
- **Purpose:** Provide an executive summary of the business's financial and operational health.
- **Features:**
    - Real-time KPIs (Cash on Hand, Total Sales, Overdue Receivables, etc.).
    - Interactive charts for sales and expense trends.
    - Low stock alerts and pending approvals notification.
- **Business Rules:** Data must be filtered by company and branch. Access is restricted by user role.
- **User Stories:** As an Owner, I want to see my daily cash position so I can make informed spending decisions.
- **Acceptance Criteria:** Dashboard loads within 2 seconds; all numbers match the General Ledger.

### 3.2 Companies & Branches
- **Purpose:** Define the organizational structure.
- **Features:**
    - Company profile management (Logo, Address, VAT number).
    - Branch creation and configuration.
    - Regional settings (Date format, Currency, Timezone).
- **Business Rules:** Each transaction must be linked to a specific branch.
- **User Stories:** As a Super Admin, I want to create a new branch for a company so they can track performance by location.
- **Acceptance Criteria:** Branch data isolation is maintained in all reports.

### 3.3 Users & Roles
- **Purpose:** Manage system access and security.
- **Features:**
    - Role-based access control (RBAC).
    - User invitation and onboarding.
    - Activity logging.
- **Business Rules:** Users must have at least one role. Password policies must be enforced.
- **User Stories:** As an Owner, I want to invite my accountant and give them full financial access but no HR access.
- **Acceptance Criteria:** Permissions are enforced at both UI and API/Database levels.

### 3.4 Customers & Suppliers (CRM)
- **Purpose:** Manage relationships with external parties.
- **Features:**
    - Master data management (Name, Contact, Tax ID).
    - Opening balances and credit limits.
    - Transaction history and statement generation.
- **Business Rules:** Tax IDs must be validated based on country rules.
- **User Stories:** As a Sales Manager, I want to set a credit limit for a customer to prevent excessive debt.
- **Acceptance Criteria:** System blocks invoice creation if it exceeds the customer's credit limit.

### 3.5 Accounting (Core Engine)
- **Purpose:** Maintain the General Ledger and financial integrity.
- **Features:**
    - Chart of Accounts (Flexible tree structure).
    - Journal Entries (Manual and Automated).
    - Financial Statements (BS, P&L, Trial Balance).
    - Tax (VAT/GST) configuration and reporting.
- **Business Rules:** Double-entry must always balance. Transactions cannot be posted to closed periods.
- **User Stories:** As an Accountant, I want to post a manual journal entry to adjust depreciation at month-end.
- **Acceptance Criteria:** The Trial Balance remains in balance after every transaction.

### 3.6 Sales & Purchase
- **Purpose:** Manage the trade lifecycle.
- **Features:**
    - Quotations/Proforma Invoices.
    - Sales Orders and Purchase Orders.
    - Invoices and Bills.
    - Credit and Debit Notes.
- **Business Rules:** Invoices must update Accounts Receivable; Bills must update Accounts Payable.
- **User Stories:** As a Salesperson, I want to convert a quotation into an invoice with one click.
- **Acceptance Criteria:** Document sequences are unique and non-skipping.

### 3.7 Inventory
- **Purpose:** Track stock levels and movements.
- **Features:**
    - Stock In (Purchase/Return).
    - Stock Out (Sales/Consumption).
    - Stock Transfers (Between branches/warehouses).
    - Adjustments (Damage/Loss).
- **Business Rules:** Inventory valuation must follow FIFO or Weighted Average.
- **User Stories:** As a Storekeeper, I want to record a stock transfer so I know where my inventory is located.
- **Acceptance Criteria:** Real-time stock levels are updated upon document posting.

### 3.8 HR & Payroll
- **Purpose:** Manage employee data and payments.
- **Features:**
    - Employee profiles and document management.
    - Attendance and Leave tracking.
    - Salary structures and Payslip generation.
- **Business Rules:** Payroll must generate appropriate accounting entries (Salary Expense Dr, Accrued Payroll Cr).
- **User Stories:** As an HR Manager, I want to generate monthly payslips for all employees based on their salary structure.
- **Acceptance Criteria:** Payslips accurately reflect deductions and net pay.

### 3.9 Fixed Assets
- **Purpose:** Track long-term assets and their depreciation.
- **Features:**
    - Asset registry.
    - Depreciation schedules (Straight-line, Declining balance).
    - Disposal and Revaluation.
- **Business Rules:** Depreciation must be posted automatically to the GL.
- **Acceptance Criteria:** Asset book value matches the Balance Sheet.

### 3.10 Budgeting
- **Purpose:** Financial planning and control.
- **Features:**
    - Annual and Monthly budget creation.
    - Budget vs. Actual reporting.
- **Business Rules:** Alerts can be set if actual spending exceeds budget by a percentage.

### 3.11 Banking & Reconciliation
- **Purpose:** Manage bank accounts and cash flow.
- **Features:**
    - Multiple bank and cash accounts.
    - Bank statement import (CSV/Excel).
    - Automated reconciliation.
- **Business Rules:** Bank balance in ERP must be reconciled to the actual bank statement.

### 3.12 Projects
- **Purpose:** Track costs and revenue for specific projects.
- **Features:**
    - Project budgeting.
    - Resource allocation.
    - Project-specific P&L.

### 3.13 Manufacturing
- **Purpose:** Manage production processes.
- **Features:**
    - Bill of Materials (BOM).
    - Work Orders.
    - Production Costing (Labor + Material + Overhead).

### 3.14 Reports & Settings
- **Purpose:** Global configuration and data output.
- **Features:**
    - Report builder.
    - Email templates.
    - Integration settings.

## 4. Acceptance Criteria (Global)
- All modules must be responsive (Web and Mobile).
- Data must be isolated by `company_id`.
- Every "Post" action must create a corresponding Journal Entry.
- System must support "Dark Mode" (Pure Black #000000).
