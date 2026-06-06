# 10 Module Requirements

## 1. Accounting Module
The core of LedGix ERP. It must maintain financial integrity and provide accurate reporting.

### Key Components:
- **Chart of Accounts (CoA):** A hierarchical list of all accounts.
- **Journal Entries:** The atomic unit of accounting.
- **Financial Periods:** Monthly/Yearly locking of transactions.

### Posting Logic:
| Event | Debit | Credit |
| :--- | :--- | :--- |
| Sales Invoice | Accounts Receivable | Sales Revenue, VAT Output |
| Customer Payment | Bank/Cash | Accounts Receivable |
| Purchase Bill | Expense/Inventory, VAT Input | Accounts Payable |
| Supplier Payment | Accounts Payable | Bank/Cash |

### Reports:
- Balance Sheet, Profit & Loss, Trial Balance, Ledger Report.

---

## 2. Sales Module
Manages the revenue lifecycle from lead to cash.

### Workflow:
`Quotation` → `Sales Order` → `Delivery Note` → `Sales Invoice` → `Customer Receipt`

### Validation:
- Customer credit limit check before invoice posting.
- Warning if selling price is below cost price.
- Check available stock if "Allow Negative Inventory" is disabled.

---

## 3. Purchase Module
Manages the expense lifecycle from request to payment.

### Workflow:
`Purchase Requisition` → `Purchase Order` → `GRN (Goods Received Note)` → `Purchase Bill` → `Supplier Payment`

### Features:
- Track landing costs (Freight, Customs) and distribute them into inventory value.
- Supplier performance tracking (Delivery time, Quality).

---

## 4. Inventory Module
Tracks the movement and value of physical goods.

### Core Features:
- **Multi-Warehouse:** Track stock across different physical locations.
- **Stock Valuation:** Support for FIFO (First-In, First-Out) and Weighted Average.
- **UOM Conversions:** e.g., Buying in "Boxes" and selling in "Units".

### Critical Logic:
- **Stock Reconciliation:** Periodic physical count vs. system count adjustments.
- **Low Stock Alerts:** Automated notifications when items fall below reorder levels.

---

## 5. Banking Module
Manages cash flow and bank relationships.

### Features:
- **Bank Reconciliation:** Matching ERP bank ledger with actual bank statements.
- **Bank Transfers:** Internal transfers between bank/cash accounts.
- **Expense Claims:** Employee reimbursement management.

---

## 6. HR & Payroll Module
Manages the workforce.

### Features:
- **Employee Master:** Personal details, documents, and contract terms.
- **Attendance:** Daily clock-in/out and leave management.
- **Payroll Engine:**
    - Earnings (Basic, Housing, Transport).
    - Deductions (Tax, Social Security, Advances).
    - Net Pay calculation.
    - Automated Journal Entry generation for salary accrual and payment.

---

## 7. Reports & Analytics
- **Dashboard KPIs:** Real-time visibility.
- **Operational Reports:** Daily sales, stock status, pending orders.
- **Audit Reports:** User activity logs, deleted records (soft-deleted), change history.
