# Repository Guidelines

## Project Structure & Module Organization

Application code lives in `lib/`: models in `models/`, Riverpod state in `providers/`, integrations in `services/`, pages in `screens/`, shared UI in `widgets/`, and helpers in `utils/`. Static content belongs in `lib/data/`; bundled files go in `assets/` and must be declared in `pubspec.yaml`. Tests live in `test/`. Platform runners occupy `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`. Firebase rules and indexes are at the root; backend code is in `functions/`.

## Build, Test, and Development Commands

- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the app on a selected device; use `flutter run -d chrome` for web.
- `flutter analyze` runs the configured `flutter_lints` checks.
- `dart format lib test` formats application and test code.
- `flutter test` runs the complete Flutter test suite.
- `flutter build ios`, `flutter build apk`, or `flutter build web` produces a platform build.
- `npm --prefix functions install` installs Firebase Functions dependencies.

Run commands from the repository root. Firebase flows require valid platform configuration and a configured Firebase project.

## Coding Style & Naming Conventions

Use two-space indentation and let `dart format` decide wrapping. Name files `snake_case.dart`, types `UpperCamelCase`, and variables, methods, and providers `lowerCamelCase`. Prefer focused widgets and services. Keep platform-neutral behavior in `lib/`; modify native runners only for platform setup. Resolve analyzer warnings rather than broadly suppressing lints.

## Testing Guidelines

Tests use `flutter_test`. Name files `*_test.dart` and tests descriptively, for example `testWidgets('settings saves theme changes', ...)`. Add widget tests for UI behavior and unit tests for models, utilities, and providers. No coverage threshold is enforced, but behavior changes should include focused regression tests. Run analysis and tests before opening a pull request.

## Commit & Pull Request Guidelines

Follow the dominant history style: `feat: ...`, `fix: ...`, `refactor: ...`, or another concise imperative subject. Keep commits scoped and avoid mixing generated build artifacts with source changes. Pull requests should explain the user-visible impact, list verification performed, link relevant issues, and include screenshots or recordings for UI changes. Call out Firebase rule, authentication, permission, or platform configuration changes explicitly.

## Agent-Specific Notes

Before architecture work, read `CLAUDE.md` and `graphify-out/GRAPH_REPORT.md`. After changing code, run `graphify update .` as required by the repository's graph documentation. Do not commit secrets, downloaded Firebase credentials, or generated build directories.
