# 19 Notification Framework

## Channels
- **In-App:** Real-time bell icon notifications.
- **Push:** Mobile notifications for urgent approvals or alerts.
- **Email:** Official documents (Invoices), weekly summaries, and password resets.
- **SMS/WhatsApp:** Payment reminders and OTPs (Future).

## Triggers
- **Document State Change:** "Invoice Approved", "Bill Paid".
- **Threshold Alerts:** "Stock Level Low", "Credit Limit Reached".
- **System Events:** "New User Invited", "Successful Backup".
- **Scheduled:** "Daily Sales Summary", "Monthly Financial Report Ready".

## Templates
- Standardized HTML templates for emails.
- Markdown support for in-app notifications.
- Placeholders for dynamic data (e.g., `{{customer_name}}`, `{{amount}}`).

## User Preferences
- Users can toggle notifications per channel.
- Quiet hours setting to suppress non-urgent push notifications.

## Escalation Logic
- If a high-priority approval is pending for > 24 hours, notify the next level manager.
- Repeated failed login attempts trigger an immediate email to the security admin.
观察到以上这些文档基本都包含在内了。接下来继续。
