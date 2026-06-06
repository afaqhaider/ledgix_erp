# 07 Database Design

## 1. Introduction
LedGix ERP uses Google Cloud Firestore as its primary database. Firestore is a document-oriented NoSQL database. While it is schema-less, this document defines the mandatory structure for our collections to ensure consistency.

## 2. Core Collections

### 2.1 `companies`
- **Path:** `/companies/{companyId}`
- **Fields:**
    - `name` (String): Legal name.
    - `logoUrl` (String): URL to Firebase Storage.
    - `taxId` (String): VAT/GST number.
    - `currency` (String): Default currency code (e.g., 'USD', 'AED').
    - `settings` (Map): Config for date formats, fiscal year start, etc.
    - `createdAt` (Timestamp).

### 2.2 `branches`
- **Path:** `/companies/{companyId}/branches/{branchId}`
- **Fields:**
    - `name` (String): Branch name.
    - `address` (String).
    - `isHeadOffice` (Boolean).
    - `isActive` (Boolean).

### 2.3 `users`
- **Path:** `/users/{uid}` (Global) or `/companies/{companyId}/users/{uid}`
- **Fields:**
    - `displayName` (String).
    - `email` (String).
    - `role` (String): Primary role in the company.
    - `assignedBranches` (Array<String>): IDs of branches user can access.

### 2.4 `customers` & `suppliers`
- **Path:** `/companies/{companyId}/contacts/{contactId}`
- **Fields:**
    - `type` (String): 'customer' or 'supplier'.
    - `name` (String).
    - `email` (String).
    - `phone` (String).
    - `openingBalance` (Number).
    - `currentBalance` (Number).
    - `creditLimit` (Number).

### 2.5 `accounts` (Chart of Accounts)
- **Path:** `/companies/{companyId}/accounts/{accountId}`
- **Fields:**
    - `code` (String): e.g., '1001'.
    - `name` (String): e.g., 'Cash in Hand'.
    - `type` (String): 'Asset', 'Liability', 'Equity', 'Income', 'Expense'.
    - `parentAccountId` (String): For tree structure.
    - `isSystemAccount` (Boolean): If true, cannot be deleted.

### 2.6 `journal_entries`
- **Path:** `/companies/{companyId}/journal_entries/{jeId}`
- **Fields:**
    - `date` (Timestamp).
    - `reference` (String): Document number (e.g., JV-001).
    - `description` (String).
    - `status` (String): 'Draft', 'Posted', 'Reversed'.
    - `totalAmount` (Number).
    - `lines` (Array<Map>):
        - `accountId` (String).
        - `description` (String).
        - `debit` (Number).
        - `credit` (Number).

### 2.7 `sales_invoices`
- **Path:** `/companies/{companyId}/sales_invoices/{invoiceId}`
- **Fields:**
    - `invoiceNumber` (String).
    - `customerId` (String).
    - `branchId` (String).
    - `date` (Timestamp).
    - `dueDate` (Timestamp).
    - `items` (Array<Map>): `productId`, `qty`, `rate`, `taxAmount`, `total`.
    - `subtotal` (Number).
    - `taxTotal` (Number).
    - `grandTotal` (Number).
    - `status` (String): 'Draft', 'Unpaid', 'Partial', 'Paid', 'Canceled'.

### 2.8 `inventory` (Stock Items)
- **Path:** `/companies/{companyId}/products/{productId}`
- **Fields:**
    - `sku` (String).
    - `name` (String).
    - `uom` (String): Unit of Measure.
    - `costPrice` (Number).
    - `sellingPrice` (Number).
    - `trackStock` (Boolean).

## 3. Validation Rules
1. **Financial Values:** All amounts must be stored as `double` or `int` (cents) to avoid floating point issues.
2. **Mandatory Audit:** Every document must include `createdBy`, `updatedBy`, `createdAt`, and `updatedAt`.
3. **Soft Deletes:** Documents should generally have an `isActive` or `isDeleted` flag instead of being permanently removed.
