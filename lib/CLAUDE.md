# Dart / Flutter conventions

Architecture rules (layering, usecases, DTO boundary, module boundaries) live in the root `CLAUDE.md`.

## State management

Riverpod (hooks_riverpod + riverpod_generator). Use `@riverpod` codegen providers, not hand-written ones, when adding new state. The retry policy in `main.dart` exponentially backs off only for `NetworkFailure`; other failures fail fast — keep your `Failure` types accurate so retries behave correctly.

## Conventions

- **Theme:** always pull colors/typography from `AppTheme` / `Theme.of(context).colorScheme`. Never hard-code colors. Design philosophy is "Clean Luxe" — flat surfaces, no `BoxShadow`/`Shadow` on widgets, charcoal-led UI with a single lavender brand accent (used only as a low-emphasis tonal container — selected chips, tags — via `primaryContainer`; high-emphasis CTAs/prices/active states use `primary` = charcoal), Material 3 tonal tokens. Full spec in `docs/ui-design-system.md`.
- **Prefer themed components over hand-rolled UI:** reach for the standard Material widget that already has a theme defined in `AppTheme` (`build()` in `lib/core/theme/app_theme.dart`) before building a custom one — e.g. `CheckboxListTile`/`ListTile` (`listTileTheme`), `ChoiceChip`/`Chip` (`chipTheme`), `Divider` (`dividerTheme`), `TextButton`/`FilledButton`/`OutlinedButton`, `Card` (`cardTheme`), `TextField` (`inputDecorationTheme`). Don't re-specify values the theme already sets (padding, border, color, thickness). If a needed style is missing, add/extend the component theme in `AppTheme` rather than styling one-off at the call site. Use `AppSpacing`/`AppRadius` tokens for spacing and radii, never raw numbers.
- **Errors:** model failures with the sealed types in `lib/core/error/failures.dart`; results use the `typed_result` package.
- **Logging:** `talker_flutter` (don't add raw `print`).
