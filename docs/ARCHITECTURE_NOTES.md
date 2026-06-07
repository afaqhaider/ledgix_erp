# Architecture Notes & Future Hardening

## Critical Actions for Cloud Functions
The following actions should be moved to server-side logic to prevent client-side manipulation:

1. **Document Numbering:** Ensuring `INV-001` sequence is strictly followed without gaps or duplicates.
2. **Document Posting:** Marking an invoice or bill as "Posted", which should make it immutable and trigger ledger entries.
3. **Ledger (Journal) Generation:** Automatically creating `journalEntries` when documents are posted.
4. **Audit Logging:** Enforcing that every write operation creates a corresponding `auditLogs` entry.
5. **Approval Transitions:** Validating that only authorized users can change the status of an approval request.
6. **Opening Balances:** Strict control over initial account balances.

## Scalability TODOs
1. **Summary Documents:** Maintain a `summaries/financials` document for dashboard KPIs to avoid counting thousands of invoices on every load.
2. **Monthly Aggregates:** Pre-calculate monthly sales/expenses for reporting.
3. **Indexing:** Ensure composite indexes are created for common filtered queries (e.g., `companyId` + `status` + `date`).
4. **Pagination:** All list views must implement `limit` and `startAfter` logic.
