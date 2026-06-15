# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working notes

- Design/spec docs under `docs/superpowers/` are gitignored and intentionally NOT committed. Write them there for reference, but never `git add -f` or commit them.

## Project

Tryzeon is a Flutter app (Dart SDK ^3.9) for AI virtual try-on and wardrobe management. Backend is Supabase (Postgres + Edge Functions in `supabase/functions/`); auth, storage, and analytics RPCs all run there. Subscriptions go through RevenueCat; crash/analytics through Firebase.

## Common Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen: riverpod, freezed, json, isar, auto_mappr, envied
dart run build_runner watch  --delete-conflicting-outputs  # incremental codegen during dev
flutter run                                                # debug on default device
flutter analyze                                            # lint (uses analysis_options.yaml; .g/.freezed/.gr files excluded)
dart fix --apply && dart format .                          # autofix + format (page_width: 90)
```

Code generation is required after editing any annotated file (`@riverpod`, `@freezed`, `@JsonSerializable`, Isar `@collection`, `@AutoMappr`, `@Envied`). If imports of `*.g.dart` / `*.freezed.dart` are missing, run build_runner.

`Env` (`lib/core/config/env.dart`) is generated from a `.env` file via `envied`; it holds `supabaseUrl`, `supabaseAnonKey`, `revenueCatApiKey`, etc.

## Architecture

### Top-level layout

- `lib/main.dart` — bootstraps Firebase, Supabase (PKCE auth flow), RevenueCat, Crashlytics; wraps app in `ProviderScope` with a custom retry policy keyed off `NetworkFailure`.
- `lib/core/` — cross-feature infrastructure: `router/` (go_router), `theme/` (`AppTheme`, Material 3 ColorScheme), `di/core_providers.dart` (shared Riverpod providers), `error/failures.dart`, `data/`, `domain/`, `modules/` (analytics, location, revenue_cat), `presentation/widgets/` (shared widgets), `extensions/`, `utils/`, `shared/`, `config/`.
- `lib/feature/` — feature-first modules. Each feature follows clean-architecture layering: `data/` (datasources, repositories, Isar collections, DTOs) → `domain/` (entities, repository interfaces, usecases) → `presentation/` (pages, widgets) plus `providers/` for Riverpod wiring.
- `lib/feature/auth/` — shared auth (Supabase + Apple/Google social sign-in).
- `lib/feature/personal/` — consumer side (try-on, wardrobe, chat, shop, profile, subscription, usage, onboarding, settings).
- `lib/feature/store/` — store-owner side (analytics, products, profile, onboarding, settings).
- `lib/feature/common/` — shared between personal and store.

### Routing

`go_router` config in `lib/core/router/app_router.dart` uses two `StatefulShellRoute` shells (`personal_shell.dart`, `store_shell.dart`) selected by user role. Route trees are split into `routes/auth_routes.dart`, `personal_routes.dart`, `store_routes.dart`, `deep_link_routes.dart`. `auth_refresh_listenable.dart` rebuilds the router on Supabase auth changes. A global `navigatorKey` (in `main.dart`) is used by the `upgrader` dialog.

### State management

Riverpod (hooks_riverpod + riverpod_generator). Use `@riverpod` codegen providers, not hand-written ones, when adding new state. The retry policy in `main.dart` exponentially backs off only for `NetworkFailure`; other failures fail fast — keep your `Failure` types accurate so retries behave correctly.

### Persistence

- **Supabase** — remote source of truth; auth uses PKCE.
- **Isar** (`isar_community`) — local cache; collections live under each feature's `data/collections/`.
- **shared_preferences** — small key/value flags.
- **flutter_cache_manager / cached_network_image** — network image caching.

### Analytics

Frontend batches events (10/5s, lifecycle-aware flush) and calls the `log_analytics_events` Supabase RPC, which inserts into `analytics_events`. An `AFTER INSERT` trigger (`on_analytics_event_inserted` → `update_analytics_summary`) upserts per-product monthly aggregates into `analytics_product_monthly_summary` for O(1) dashboard reads. See README.md for the full diagram. Event types: `view`, `try_on`, `purchase_click`.

### Edge Functions

`supabase/functions/`: `chat`, `tryon`, `delete-account`, `cleanup-orphan-images`, `revenuecat-webhook`, plus `_shared/`. The `tryon` function is the AI image-generation entry point; `revenuecat-webhook` reconciles subscription state.

### Supabase migrations

- Schema is cumulative: to find a column/type/function's real state, `grep -rn "<name>" supabase/migrations/` and trace to the **last** file that touches it — never treat the baseline dump as current.
- New migration timestamps must be later than the newest existing file, or `supabase db push` rejects them as out-of-order.
- Enums can't drop/merge values in place: cast dependent columns to `text` → remap data → rebuild type → cast back → drop old type.

## Conventions

- **Lints (`analysis_options.yaml`):** `prefer_single_quotes`, `always_declare_return_types`, `prefer_final_locals`, `directives_ordering` are enforced; `always_use_package_imports` is off (relative imports allowed within a feature).
- **Formatter** is configured to `page_width: 90`.
- **Theme:** always pull colors/typography from `AppTheme` / `Theme.of(context).colorScheme`. Never hard-code colors. Design philosophy is "Clean Luxe" — flat surfaces, no `BoxShadow`/`Shadow` on widgets, single Terracotta accent, Material 3 tonal tokens. Full spec in `docs/ui-design-system.md`.
- **Prefer themed components over hand-rolled UI:** reach for the standard Material widget that already has a theme defined in `AppTheme` (`build()` in `lib/core/theme/app_theme.dart`) before building a custom one — e.g. `CheckboxListTile`/`ListTile` (`listTileTheme`), `ChoiceChip`/`Chip` (`chipTheme`), `Divider` (`dividerTheme`), `TextButton`/`FilledButton`/`OutlinedButton`, `Card` (`cardTheme`), `TextField` (`inputDecorationTheme`). Don't re-specify values the theme already sets (padding, border, color, thickness). If a needed style is missing, add/extend the component theme in `AppTheme` rather than styling one-off at the call site. Use `AppSpacing`/`AppRadius` tokens for spacing and radii, never raw numbers.
- **Errors:** model failures with the sealed types in `lib/core/error/failures.dart`; results use the `typed_result` package.
- **Logging:** `talker_flutter` (don't add raw `print`).

