# 13 API Design (Future REST)

## Standards
- **Version:** `/api/v1`
- **Format:** JSON
- **Auth:** Bearer Token (JWT)
- **Status Codes:**
  - `200 OK`: Success
  - `201 Created`: Post success
  - `400 Bad Request`: Validation error
  - `401 Unauthorized`: Missing/Invalid token
  - `403 Forbidden`: Insufficient permissions
  - `404 Not Found`: Resource missing
  - `500 Server Error`: Internal failure

## Endpoints

### Authentication
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/mfa-verify`

### Core
- `GET /companies`
- `GET /companies/{id}/branches`
- `GET /accounts` (Searchable/Filterable)

### Transactions
- `GET /invoices`
- `POST /invoices`
- `PUT /invoices/{id}/post`
- `GET /bills`
- `POST /journal-entries`

### Reports
- `GET /reports/balance-sheet?date=YYYY-MM-DD`
- `GET /reports/profit-loss?start=...&end=...`

## Pagination
Standard `limit` and `offset` (or `cursor`) parameters.
`GET /invoices?limit=20&offset=40`

## Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "The due date cannot be before the invoice date.",
    "details": [
      { "field": "due_date", "issue": "chronology" }
    ]
  }
}
```
