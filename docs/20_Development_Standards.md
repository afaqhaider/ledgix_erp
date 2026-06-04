# 20 Development Standards

## Mandatory Engineering Rules
1. **No Hardcoded Colors:** Use `Theme.of(context).colorScheme`.
2. **No Hardcoded Currencies:** Use `CurrencyProvider` or equivalent setting.
3. **No Hardcoded Formats:** Dates and numbers must pass through `LedGixFormatter`.
4. **No Duplicate Business Logic:** Sensitive logic (e.g., posting JEs) must reside in Cloud Functions or a centralized Service layer, never just in the UI.
5. **Feature-Based Architecture:** Organize code by feature (e.g., `features/sales`, `features/accounting`) rather than by type (e.g., `models/`, `views/`).

## Coding Style
- **Naming:** `PascalCase` for classes, `camelCase` for variables/functions, `snake_case` for database fields.
- **Null Safety:** Strict adherence to Dart null safety.
- **Documentation:** Every public function and class must have a docstring (`///`).

## Clean Code Principles
- **DRY (Don't Repeat Yourself):** Extract common widgets and logic.
- **SOLID:** Especially Single Responsibility - keep widgets small.
- **KISS (Keep It Simple, Stupid):** Avoid over-engineering solutions for simple features.

## State Management
- Preferred: `Provider`, `Riverpod`, or `Bloc` (consistent across the project).
- Local state for simple UI toggles is acceptable.

## Commit Guidelines
- Use conventional commits: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`.
- Example: `feat(accounting): implement journal entry validation`
