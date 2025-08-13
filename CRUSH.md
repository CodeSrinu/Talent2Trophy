# CRUSH.md
## Commands
- Build: `flutter build apk` (Android), `flutter build ipa` (iOS)
- Lint: `flutter analyze`
- Test all: `flutter test`
- Test single: `flutter test test/<filename>.dart`
- Format: `dart format lib/`

## Code Style
- **Imports**: Sort `dart:`, `package:`, relative paths alphabetically
- **Formatting**: 2-space indent, no semicolons, 80-char lines
- **Types**: Prefer explicit types; use `var` only for obvious cases
- **Naming**: `lowerCamelCase` (vars), `PascalCase` (classes), `snake_case` (files)
- **Error Handling**: Always `try`/`catch` async code; log errors

## Notes
- Test files in `test/` use `_test.dart` suffix
- Use `analysis_options.yaml` rules from root
- Run `flutter analyze` before commit