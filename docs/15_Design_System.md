# 15 Design System

## Components

### 1. Atomic Elements
- **Colors:** Primary, Secondary, Success, Error, Warning, Surface, Background.
- **Typography:** Display, Heading, Body, Label, Caption.
- **Icons:** Material Design Rounded set.

### 2. Molecules
- **Input Fields:** Text, Number (with calc), Date, Dropdown (with search).
- **Cards:** Standard containers for metrics and list items.
- **Badges:** Status indicators (Draft, Posted, Overdue).

### 3. Organisms
- **Data Table:** Feature-rich grid with sorting and filtering.
- **Form Builder:** Standardized layout for document entry.
- **Search Bar:** Global and context-specific search with suggestions.

### 4. Layouts
- **App Shell:** Navigation (Side/Bottom) + Top Bar (Search, Profile).
- **Dashboard Grid:** Responsive tile system.
- **Detail View:** Header (Primary Info) + Tabs (Detailed Data/Audit Trail).

## Theme Switching
Support for System, Light, and Dark (Pure Black) modes. Theme must be persisted in local storage and synced with user profile.

## Reusable Widget Library (Flutter)
- `LedGixButton`
- `LedGixTextField`
- `LedGixCurrencyField`
- `LedGixDataTable`
- `LedGixBadge`
- `LedGixLoadingOverlay`
