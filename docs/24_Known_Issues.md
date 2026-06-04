# 24 Known Issues

## Critical
- *None currently reported.*

## High
- **Document numbers consumed before save:** If a user opens a new invoice and closes it without saving, the auto-incremented number is "skipped". (Plan: Implement temporary reservation or client-side generation upon save).
- **Theme Inconsistencies:** Some dialogs do not inherit the Pure Black background correctly on iOS.

## Medium
- **Amount formatting inconsistencies:** Some reports show 4 decimal places while the UI shows 2.
- **Currency formatting:** Negative amounts are shown as `-100.00` in some places and `(100.00)` in others. (Standardize to `(100.00)`).

## Low
- **Dashboard Refresh:** Manual refresh required to see latest transaction metrics in some edge cases.
- **Table Scroll:** Horizontal scroll on small mobile devices is sometimes difficult to trigger.

## Technical Debt
- Need to migrate from `Provider` to `Riverpod` for better testability.
- Firestore rules need simplification; currently too verbose.
- Shared logic between Web and Mobile for PDF generation needs unification.
