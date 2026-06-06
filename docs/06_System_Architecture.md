# 06 System Architecture

## 1. Current Architecture (Firebase)
LedGix ERP is currently built as a modern serverless application leveraging the Firebase suite for speed, scalability, and real-time capabilities.

### Tech Stack:
- **Frontend:** Flutter (Web, Android, iOS)
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore (NoSQL)
- **Storage:** Firebase Storage
- **Backend Logic:** Cloud Functions (Node.js/TypeScript)
- **Hosting:** Firebase Hosting

### High-Level Data Flow:
```text
Flutter App (UI)
      ↓
Firebase Auth (Identity)
      ↓
Cloud Firestore (State/Data)
      ↓
Cloud Functions (Business Logic/Integrations)
      ↓
Firebase Storage (Assets/Documents)
```

## 2. Technical Strategy
- **Feature-Based Architecture:** Code is organized by features (e.g., `features/accounting`, `features/sales`) rather than layers.
- **State Management:** Using Riverpod for robust and testable state handling.
- **Service Layer:** All business logic resides in service classes, making it independent of the UI and easy to move to a backend API later.
- **Repository Pattern:** Abstracting data access to allow switching from Firestore to PostgreSQL in the future.

## 3. Security & Access Control
- **Firestore Security Rules:** Primary defense for data isolation. Rules verify `request.auth.uid` and check if the user belongs to the `company_id` they are accessing.
- **RBAC (Role-Based Access Control):** Custom claims or a `user_roles` collection to manage permissions.

## 4. Future Enterprise Architecture
As the platform scales to enterprise levels, we will transition to:

```text
Flutter (Frontend)
      ↓
API Gateway (Kong/Nginx)
      ↓
Microservices (Go/Node.js)
      ↓
PostgreSQL (Relational Database)
      ↓
Redis (Caching)
      ↓
Data Warehouse (BigQuery/Snowflake for Analytics)
```

## 5. Key Infrastructure Components
- **Auth Flow:** User logs in → Receives JWT → App attaches JWT to Firestore/Function requests.
- **Reporting Flow:** Firestore Query → Service Logic → UI (Small reports) | Cloud Function → PDF Gen → UI (Large reports).
- **Notification Flow:** Trigger (e.g., Overdue Invoice) → Cloud Function → Firebase Cloud Messaging (FCM) / SendGrid Email.

## 6. Migration Path
- The use of `Service` and `Repository` interfaces in Flutter ensures that when we move to a REST API, we only need to implement a `RestRepository` while the `Service` and `UI` remain unchanged.
