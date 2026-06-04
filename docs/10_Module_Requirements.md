# 10 Module Requirements

## 1. Accounting Module
### Fields
- `account_name`, `account_code`, `account_type`, `is_active`, `balance`.
### Validation
- Account code must be unique.
- Cannot delete an account with a non-zero balance.
### Posting Logic
- Real-time balance updates on document posting.
### Reports
- Balance Sheet, Profit & Loss, Trial Balance, General Ledger.

## 2. Inventory Module
### Fields
- `sku`, `product_name`, `uom`, `category`, `current_stock`, `reorder_level`.
### Workflows
- Stock In (Purchase/Return)
- Stock Out (Sales/Internal)
- Stock Adjustment (Manual)
### Audit Requirements
- Track history of stock movements for every SKU.

## 3. Sales Module
### Fields
- `customer_id`, `invoice_date`, `due_date`, `items_list`, `tax_total`, `grand_total`.
### Notifications
- Send email to customer on invoice posting.
- Alert sales rep on payment receipt.
### Exceptions
- Handling of sales returns (Credit Notes).

## 4. HR & Payroll
### Fields
- `employee_id`, `basic_salary`, `allowances`, `deductions`, `joining_date`.
### Posting Logic
- Generate Salary Payable and Expense entries on payroll run.
### Permissions
- Highly restricted access to salary details.
