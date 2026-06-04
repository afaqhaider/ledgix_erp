# 08 Data Model

## Entity Relationships

### Organizational Hierarchy
- **Company** (1) ↔ (N) **Branch**
- **Company** (1) ↔ (N) **Users** (via Mapping)
- **Company** (1) ↔ (1) **Chart of Accounts**

### Master Data
- **Customer** (1) ↔ (N) **Sales Invoice**
- **Supplier** (1) ↔ (N) **Purchase Bill**
- **Product** (1) ↔ (N) **Inventory Transaction**

### Financial Flow
- **Sales Invoice** (1) ↔ (1) **Journal Entry**
- **Purchase Bill** (1) ↔ (1) **Journal Entry**
- **Payment** (1) ↔ (1) **Journal Entry**
- **Journal Entry** (1) ↔ (N) **Journal Lines**

## State Transitions

### Sales Invoice State
`Draft` → `Approved` → `Posted` → `Paid` | `Partially Paid`
                     ↓
                  `Cancelled`

### Purchase Bill State
`Draft` → `Posted` → `Paid` | `Partially Paid`

## Data Integrity Rules
- Every `Journal Entry` sum of `debits` must equal sum of `credits`.
- `Journal Lines` must reference a valid `Account ID`.
- `Sales Invoices` must reference a valid `Customer ID`.
- Documents in `Posted` state cannot be modified; they must be reversed.
