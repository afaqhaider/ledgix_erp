# 04 Functional Requirements

## Sales Invoice
- **Create:** User can input customer, items, taxes, and discounts.
- **Edit:** Allowed only if the invoice is in 'Draft' status.
- **Delete:** Allowed for 'Draft' only. Otherwise, 'Cancel' or 'Credit Note' required.
- **Approve:** Move from Draft to Approved.
- **Post:** Generate accounting entries and update ledger.
- **Print/Email:** Generate PDF and send via integrated mail service.

## Inventory Management
- **Receive Stock:** Increase stock on hand via Purchase Bill or Adjustment.
- **Issue Stock:** Decrease stock via Sales Invoice or Internal Use.
- **Transfer Stock:** Move stock between branches/warehouses.
- **Adjust Stock:** Correct stock levels with reason codes (damage, loss).

## Accounting Operations
- **Journal Entry:** Manual entry for adjustments.
- **Period Closing:** Lock transactions for a specific month.
- **Year-End Closing:** Transfer P&L balances to Retained Earnings.
- **Reversals:** One-click reversal of any posted entry with a linked audit trail.

## Multi-Currency
- **Exchange Rates:** Fetch daily rates or set manually.
- **Realized/Unrealized Gain/Loss:** Automatic calculation on payment.

## Document Numbering
- **Sequences:** Customizable prefixes and numbering for each document type (e.g., INV-2024-001).
- **Uniqueness:** Guaranteed no duplicate document numbers within a company.
