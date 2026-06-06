# 04 Functional Requirements

## 1. Introduction
This document details the functional requirements for LedGix ERP, specifying exactly what the system should do.

## 2. Core Modules Functional Details

### 2.1 Sales Invoice
- **Create:**
    - Select Customer from dropdown (with search).
    - Select Branch.
    - Add multiple line items (Products/Services).
    - Automatic calculation of subtotal, tax, and total.
    - Set due date and terms.
- **Draft Status:**
    - Allow saving as draft.
    - Drafts do not affect the General Ledger or Inventory levels.
- **Approve & Post:**
    - Validation of mandatory fields.
    - Check customer credit limit.
    - Upon posting:
        - Generate unique Invoice Number (e.g., INV-0001).
        - Create Accounting Entry: `Dr Accounts Receivable`, `Cr Sales Revenue`, `Cr Output VAT`.
        - Reduce Inventory (if items are inventory-tracked).
        - Mark as 'Unpaid'.
- **Edit/Delete:**
    - Editing allowed only in 'Draft'.
    - Deletion allowed only in 'Draft'.
    - Posted invoices can only be 'Canceled' (if no payments linked) or 'Reversed' via Credit Note.
- **Printing & Sharing:**
    - Generate PDF based on company template.
    - Email PDF directly to customer.
    - Download PDF for local storage.

### 2.2 Purchase Bill
- **Create:**
    - Select Supplier.
    - Input Supplier's Invoice Number.
    - Add line items with cost and tax.
- **Post:**
    - Create Accounting Entry: `Dr Expense/Inventory`, `Dr Input VAT`, `Cr Accounts Payable`.
    - Increase Inventory levels.
- **Payment Linkage:**
    - Ability to link one or more payments to a bill.

### 2.3 Inventory Management
- **Receive Stock (GRN - Goods Received Note):**
    - Record items received from suppliers.
    - Link to a Purchase Order.
    - Update "Quantity on Hand".
- **Stock Adjustment:**
    - Manual adjustment for breakage, loss, or initial stock upload.
    - Requires a reason code and creates a Journal Entry: `Dr/Cr Stock Adjustment Expense`, `Cr/Dr Inventory`.
- **Stock Transfer:**
    - Move stock from Branch A to Branch B.
    - 'In-transit' status support for long-distance transfers.

### 2.4 Accounting Engine
- **Chart of Accounts (CoA):**
    - Create/Edit accounts.
    - Support for Account Types: Asset, Liability, Equity, Income, Expense.
    - Parent-Child relationships (Sub-accounts).
- **Journal Entry (Manual):**
    - Multi-line entry.
    - Must balance (Total Dr = Total Cr).
    - Ability to attach supporting documents (Images/PDFs).
- **Automated Posting:**
    - Every operational document (Invoice, Bill, Payment) must have a predefined "Posting Rule" that generates JEs automatically.

### 2.5 Banking & Payments
- **Customer Receipt:**
    - Record payment received from customer.
    - Apply to one or more outstanding invoices.
    - Entry: `Dr Bank/Cash`, `Cr Accounts Receivable`.
- **Supplier Payment:**
    - Record payment made to supplier.
    - Apply to one or more outstanding bills.
    - Entry: `Dr Accounts Payable`, `Cr Bank/Cash`.
- **Bank Reconciliation:**
    - Upload CSV/Excel statement.
    - Match statement lines with ERP transactions.
    - Highlight discrepancies.

### 2.6 User Management
- **Authentication:**
    - Login via Email/Password.
    - Password reset via Email.
    - Session management (Auto logout after inactivity).
- **Authorization:**
    - Check permissions before every action (Create, Edit, Post, etc.).
    - Filter data based on user's assigned branches.

### 2.7 Reporting
- **Standard Reports:**
    - Balance Sheet (as of date).
    - Profit & Loss (date range).
    - Trial Balance.
    - General Ledger (per account).
    - Customer/Supplier Aging.
    - Inventory Valuation.
- **Exporting:**
    - All reports must be exportable to PDF and Excel.
- **Filtering:**
    - Filter by Date, Branch, Project, or Cost Center.

## 3. Workflow States
Most documents (Invoices, Bills, Orders) must follow a state machine:
`Draft` → `Pending Approval` → `Approved` → `Posted` → `Paid/Partial` → `Closed`

## 4. System Logic
- **Negative Inventory:** System setting to allow or disallow selling items not in stock.
- **Zero-Value Transactions:** Generally disallowed unless for specific gift/sample reasons.
- **Back-dating:** Restricted to users with "Back-date" permission; limited to the current open period.
