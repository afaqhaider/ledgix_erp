# 14 UI/UX Standards

## Principles
- **Clarity:** Data density without clutter.
- **Consistency:** Similar actions must behave identically.
- **Feedback:** Users must know when an action is successful or has failed.

## Mandatory Formatting

### Amounts
- Use thousands separators and 2 decimal places.
- Alignment: Right-aligned in tables.
- Colors: Positive (Green/Default), Negative (Red).
- Example: `1,250.50`, `(500.00)` or `-500.00`.

### Currencies
- **No hardcoding.**
- Always display currency code or symbol from company settings.
- Example: `SAR 1,000.00`, `$ 50.00`.

### Dates
- Standard: `DD-MMM-YYYY` (e.g., 25-OCT-2023).
- Input: Date pickers with localized manual entry.

## Theme & Colors
- **Main Theme:** Pure Black (`#000000`) for true OLED dark mode.
- **Primary Color:** Deep Teal or Electric Blue (TBD).
- **Secondary Color:** Slate Gray for borders/dividers.
- **Surface Colors:** Dark Gray (`#121212`) for cards/dialogs.

## Typography
- **Primary Font:** Inter or Roboto for readability.
- **Monospace:** JetBrains Mono for account codes and amounts.

## Interaction Design
- **Buttons:**
  - Primary: Solid fill.
  - Secondary: Outlined.
  - Danger: Red solid/outline.
- **Tables:** Sticky headers, row hover states, and paginated/infinite scroll.
- **Dialogs:** Centered on desktop, bottom sheets on mobile.

## Responsiveness
- **Desktop:** Multi-column layouts, side navigation.
- **Tablet:** Collapsible side nav, grid adjustments.
- **Mobile:** Single column, bottom navigation, focus on search and quick actions.
