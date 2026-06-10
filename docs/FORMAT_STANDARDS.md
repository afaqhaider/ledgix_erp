# LedGix ERP - Format Standards

This document defines the mandatory formatting laws for LedGix ERP. No raw formatting is allowed in UI components.

## 1. Currency & Amounts

All monetary amounts MUST be formatted using `AppFormatters.formatCurrency`.

**Required Format:** `1,000.00`
- Thousands separator: Comma (`,`)
- Decimal separator: Dot (`.`)
- Precision: Always 2 decimal places.

**Rules:**
- No raw `toString()` on doubles.
- No `AED` or `$` symbols inside the amount itself (Currency symbols should be handled by the parent widget or specified as a prefix/suffix if required).
- Zero must be displayed as `0.00`.

**Implementation:**
```dart
AppFormatters.formatCurrency(amount); // Returns "1,234.56"
```

## 2. Dates

All dates MUST be formatted using `AppFormatters.formatDate`.

**Required Format:** `dd/MM/yyyy` (e.g., `31/12/2023`)

**Rules:**
- No `DateTime.toString()`.
- No random locale-based formats.
- Use `AppFormatters.formatDateTime` for timestamps that include time.

**Implementation:**
```dart
AppFormatters.formatDate(dateTime); // Returns "25/12/2023"
```

## 3. Violations

- Any PR containing `intl.DateFormat` directly in a UI Screen will be rejected.
- Any PR containing `amount.toStringAsFixed(2)` directly in a UI Screen will be rejected.
- Use the central `AppFormatters` utility.
