# CLAUDE.md

## Working notes

- Design/spec docs under `docs/superpowers/` are gitignored and intentionally NOT committed. Write them there for reference, but never `git add -f` or commit them.
- Development in this project does not require creating a branch — make changes directly on `main` and commit there. The user manages these changes themselves.
- Always propose the best-practice solution. Do not compromise the design to minimize change scope or migration effort — optimize for correctness and quality, not for avoiding churn.
- Dart/Flutter conventions (theme, state management, errors, logging) live in `lib/CLAUDE.md`.

## Common Commands

```bash
dart run build_runner build --delete-conflicting-outputs   # codegen: riverpod, freezed, json, isar, auto_mappr, envied
dart run build_runner watch  --delete-conflicting-outputs  # incremental codegen during dev
```

Code generation is required after editing any annotated file (`@riverpod`, `@freezed`, `@JsonSerializable`, Isar `@collection`, `@AutoMappr`, `@Envied`). If imports of `*.g.dart` / `*.freezed.dart` are missing, run build_runner.

`Env` (`lib/core/config/env.dart`) is generated from a `.env` file via `envied`. The `.env` file must define all five keys or codegen fails: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUE_CAT_API_KEY`, `CHOTTULINK_API_KEY`, `R2_PUBLIC_IMAGES_BASE_URL`.

## Architecture

### Architecture rules

Every feature follows Clean Architecture. When adding code, these are hard rules, not suggestions:

- **Layering:** `data/` (datasources, models/DTOs, Isar collections, repository impls, mappers) → `domain/` (entities, repository interfaces, usecases) → `presentation/` (pages, widgets). Presentation NEVER imports `data/` or the Supabase client. All DI/wiring providers live in the feature's top-level `providers/` folder — never under `presentation/providers/` (state notifiers used only by the UI may stay in `presentation/`, but anything that constructs datasources/repositories goes in `providers/`).
- **Usecases:** presentation/providers call usecases, never repositories directly. Usecases expose `call()` returning `Result<T, Failure>`. Multi-field inputs use a freezed params object (e.g. `CreateProductParams`) — never long positional argument lists. Name usecases as verb phrases without a `UseCase` suffix (`CreateProduct`, not `CreateProductUseCase`).
- **DTO boundary:** Supabase/JSON rows are decoded into data models only inside `data/`; map to domain entities via auto_mappr (the feature mappr hubs, e.g. `personal_mappr.dart` / `store_mappr.dart`). Domain entities never expose `fromJson`/`toJson`.
- **Module boundaries:** a feature may depend on another feature's `domain/` (entities, usecases, repository interfaces) or on `feature/common/*` — never on another feature's `data/` internals. If two features need the same DTO, promote the concept to `common/` or expose it through a domain contract.
- **`feature/common/*` layout:** same nested layout as features (`domain/entities/`, not a flat `entities/` folder).
- **`core/modules/*` use the service pattern, not repository + usecase** (template: `location`). These are infrastructure (location, short_link, analytics), not business features — abstract the capability behind an interface in `domain/services/`, put the implementation in `data/services/`, and keep domain types in `domain/entities/`. Consumers (providers, pages) depend on the interface, never the concrete impl or a raw datasource. Do NOT add a usecase layer here.
- **Constants:** every table name, storage bucket, edge-function name, RPC name, and route segment is a constant in `AppConstants` / `AppRoutes`. No raw strings at call sites.
- **Exception mapping:** extend `mapExceptionToFailure` with typed `is` checks when introducing a new error source. Never match on `toString()` contents, and never swallow errors with a bare `catch (_)` — at minimum log via `AppLogger`.
- **Widgets stay thin:** no business logic (network calls, encoding, orchestration) inside `build()` or inline page callbacks — put it in a notifier/controller or usecase that returns `Result`.

### Analytics

Analytics pipeline (event batching → RPC → trigger → monthly summary) is documented in README.md §Analytics System.

