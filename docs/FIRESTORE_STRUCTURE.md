# Firestore Database Structure

## Global Collections

### `users/{uid}`
Global profile for an authenticated user.
- `uid`: string (Document ID)
- `email`: string
- `displayName`: string
- `photoUrl`: string?
- `defaultCompanyId`: string?
- `createdAt`: timestamp
- `updatedAt`: timestamp

## Company Collections

### `companies/{companyId}`
Top-level document for a tenant.
- `id`: string (Document ID)
- `companyLegalName`: string
- `tradeName`: string
- `companyLogoUrl`: string?
- ... (other company settings)

### `companies/{companyId}/members/{uid}`
Canonical membership model.
- `uid`: string
- `email`: string
- `displayName`: string
- `role`: string (superAdmin, owner, admin, accountant, cashier, sales, purchase, storekeeper, hr, employee, customerPortal, supplierPortal)
- `status`: string (invited, active, disabled)
- `userType`: string (internal, customerPortal, supplierPortal)
- `customerId`: string? (required for customerPortal)
- `supplierId`: string? (required for supplierPortal)
- `permissions`: list<string>
- `createdAt`: timestamp
- `updatedAt`: timestamp

### `companies/{companyId}/chartOfAccounts/{accountId}`
Chart of Accounts.

### `companies/{companyId}/salesInvoices/{invoiceId}`
Sales Invoices.

### `companies/{companyId}/purchaseOrders/{poId}`
Purchase Orders.

### `companies/{companyId}/supplierBills/{billId}`
Supplier Bills.

### `companies/{companyId}/customers/{customerId}`
Customers.

### `companies/{companyId}/suppliers/{supplierId}`
Suppliers.

### `companies/{companyId}/customerPayments/{paymentId}`
Customer Payments.

### `companies/{companyId}/supplierPayments/{paymentId}`
Supplier Payments.

### `companies/{companyId}/journalEntries/{entryId}`
Journal Entries.

### `companies/{companyId}/bankAccounts/{accountId}`
Bank Accounts.

### `companies/{companyId}/quotations/{quotationId}`
Quotations.

### `companies/{companyId}/bankStatementEntries/{entryId}`
Bank Statement Entries.

### `companies/{companyId}/approvals/{approvalId}`
Approval Workflows.

### `companies/{companyId}/auditLogs/{logId}`
Audit Logs.

### `companies/{companyId}/branches/{branchId}`
Branches.

### `companies/{companyId}/items/{itemId}`
Inventory Items.

### `companies/{companyId}/itemCategories/{categoryId}`
Inventory Categories.

### `companies/{companyId}/warehouses/{warehouseId}`
Warehouses.

### `companies/{companyId}/unitsOfMeasure/{uomId}`
Units of Measure.

### `companies/{companyId}/uomConversions/{conversionId}`
UOM Conversions.

### `companies/{companyId}/goodsReceivedNotes/{grnId}`
Goods Received Notes.

### `companies/{companyId}/deliveryNotes/{dnId}`
Delivery Notes.

### `companies/{companyId}/inventoryTransfers/{transferId}`
Inventory Transfers.

### `companies/{companyId}/physicalVerifications/{pvId}`
Physical Verifications.

### `companies/{companyId}/stockBalances/{balanceId}`
Stock Balances.

### `companies/{companyId}/inventoryTransactions/{txId}`
Inventory Transactions / Stock Ledger.
