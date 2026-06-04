# 07 Database Design (Firestore)

## Collection Structure

### `companies`
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | Unique Company ID |
| `name` | string | Legal Name |
| `currency` | string | Base Currency (e.g., USD) |
| `settings` | map | Formatting and regional settings |

### `branches`
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | Unique Branch ID |
| `company_id` | string | Reference to Company |
| `name` | string | Branch Name |

### `users`
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | string | Firebase Auth UID |
| `email` | string | User Email |
| `role` | string | User Role (e.g., 'admin') |
| `companies` | array | List of company IDs the user can access |

### `accounts` (Chart of Accounts)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | Account Code (e.g., 1010) |
| `name` | string | Account Name |
| `type` | string | Asset, Liability, Equity, Revenue, Expense |
| `parent_id` | string | For hierarchical COA |

### `journal_entries`
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | Entry ID |
| `date` | timestamp | Transaction Date |
| `reference` | string | Source Document Reference |
| `lines` | array[map] | List of debit/credit lines |

### `journal_lines` (Embedded or Sub-collection)
| Field | Type | Description |
| :--- | :--- | :--- |
| `account_id` | string | Reference to Account |
| `debit` | number | Amount (positive) |
| `credit` | number | Amount (positive) |
| `description`| string | Line item description |

### `products`
| Field | Type | Description |
| :--- | :--- | :--- |
| `sku` | string | Stock Keeping Unit |
| `name` | string | Product Name |
| `cost_price` | number | Standard or Average Cost |
| `sale_price` | number | Default Selling Price |

## Indexing Strategy
- Composite indexes for `company_id` + `status` + `date`.
- Collection group indexes for cross-branch reporting.
