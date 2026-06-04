# 11 Accounting Engine

## Fundamental Principles
LedGix ERP is built on **Double-Entry Bookkeeping**. Every transaction must involve at least two accounts, where total debits equal total credits.

## Chart of Accounts (COA) Structure
1. **Assets (1000 - 1999):** Cash, Bank, AR, Inventory, Fixed Assets.
2. **Liabilities (2000 - 2999):** AP, Loans, Accrued Expenses.
3. **Equity (3000 - 3999):** Capital, Retained Earnings.
4. **Revenue (4000 - 4999):** Sales, Service Income.
5. **Expenses (5000 - 5999):** COGS, Salaries, Rent, Utilities.

## Posting Examples

### 1. Sales Invoice (Credit Sale)
*When a sale is made:*
- **Dr** Accounts Receivable (Asset ↑)
- **Cr** Revenue (Revenue ↑)
- **Cr** VAT Payable (Liability ↑)

### 2. Customer Receipt
*When money is received:*
- **Dr** Bank/Cash (Asset ↑)
- **Cr** Accounts Receivable (Asset ↓)

### 3. Inventory Purchase (Credit)
*When stock is received:*
- **Dr** Inventory (Asset ↑)
- **Cr** Accounts Payable (Liability ↑)

### 4. Inventory Consumption (COGS)
*Triggered by Sales Invoice Posting:*
- **Dr** Cost of Goods Sold (Expense ↑)
- **Cr** Inventory (Asset ↓)

## Period Closing
- **Soft Close:** Prevents editing but allows authorized adjustments.
- **Hard Close:** Total lock on a financial period.
- **Year-End:** Automation to zero out Revenue/Expense accounts and move net balance to Retained Earnings.

## Multi-Currency Logic
- **Base Currency:** The currency of the company.
- **Foreign Currency:** The currency of the transaction.
- **Exchange Difference:** Calculated at the time of payment/settlement.
  - *Example:* Invoice at 1 USD = 3.75 SAR, Payment at 1 USD = 3.76 SAR. Difference posted to "Forex Gain/Loss" account.
