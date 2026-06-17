# Repository Guidelines

## Project Structure & Module Organization
This is a Flutter application for logistics and delivery, utilizing **Riverpod** for state management and a layered architecture:

- **lib/Screens/**: UI implementation using `ConsumerStatefulWidget` or `ConsumerWidget`.
- **lib/repository/**: Data access layer. Repositories handle API calls using `AuthClient` and return models.
- **lib/models/**: Data models with `fromJson` serialization.
- **lib/widgets/**: Reusable UI components (cards, text fields, etc.).
- **lib/utils/**: Authentication, token storage, and persistent storage management.
- **lib/config/**: API endpoints and environment-specific configurations.
- **lib/global/**: Application-wide themes and compression utilities.

## Build, Test, and Development Commands
Use standard Flutter CLI commands for development:

- **Install dependencies**: `flutter pub get`
- **Run the app**: `flutter run`
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`
- **Clean build artifacts**: `flutter clean`
- **Build Android (APK)**: `flutter build apk`
- **Build iOS**: `flutter build ios`

## Coding Style & Naming Conventions
- Enforced by `flutter_lints` as defined in [./analysis_options.yaml](./analysis_options.yaml).
- Follow standard Dart naming conventions: `UpperCamelCase` for classes/enums, `lowerCamelCase` for variables/functions, and `snake_case` for file names.
- Prefer `const` constructors for widgets where possible to optimize performance.

## State Management Guidelines
- Use `StateNotifierProvider` for logic that manages asynchronous state (e.g., `AsyncValue`).
- Use `Provider` for read-only repositories or static configuration.
- UI components should access providers via `ref.watch` (for rebuilding) or `ref.read` (for one-time actions).

## Testing Guidelines
- Widget tests are located in the [./test/](./test/) directory.
- Use `flutter test` to execute the entire test suite.

## Commit Guidelines
- Use descriptive commit messages.
- Common pattern: `[scope] description` or simple descriptive text (e.g., `first commit`).
