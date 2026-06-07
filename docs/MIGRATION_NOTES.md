# Migration Notes

## Actions Required for Existing Data

1. **User Data Migration:**
   - Move `role` and `companyId` from `users/{uid}` to `companies/{companyId}/members/{uid}`.
   - Clean `users/{uid}` to only contain global profile fields.

2. **Collection Renaming:**
   - `accounts` -> `chartOfAccounts`
   - `invoices` -> `salesInvoices`
   - `audit_logs` -> `auditLogs`
   - `inventoryItems` -> `items`
   - `inventoryCategories` -> `itemCategories`
   - `uoms` -> `unitsOfMeasure`
   - `grns` -> `goodsReceivedNotes`
   - `stockLedger` -> `inventoryTransactions`

3. **Data Integrity Update:**
   - Ensure all documents under `companies/{companyId}/...` have a `companyId` field for redundancy and query filtering.

4. **Membership Status:**
   - Set all existing users to `status: 'active'` and `userType: 'internal'`.
