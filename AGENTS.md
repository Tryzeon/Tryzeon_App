# AGENTS.md - Tryzeon App

> Guidelines for AI coding agents working in this Flutter/Dart codebase.

## Quick Reference

| Task | Command |
|------|---------|
| Get dependencies | `flutter pub get` |
| Run app (debug) | `flutter run` |
| Analyze code | `flutter analyze` |
| Format + fix | `dart fix --apply && dart format .` |
| Build APK | `flutter build apk` |
| Run tests | `flutter test` |
| Run single test | `flutter test test/path/to_test.dart` |

## Tech Stack
- **Flutter 3.9+, Dart 3.9+** | **State**: Riverpod + Flutter Hooks
- **Backend**: Supabase | **Result Type**: `typed_result` | **Logging**: `AppLogger`

## Architecture: Clean Architecture + Feature-First

```
lib/
├── core/                    # Shared utils, theme, widgets, AppLogger
├── feature/
│   ├── auth/                # Authentication
│   ├── common/              # Shared modules
│   ├── personal/            # Personal user features
│   │   └── wardrobe/        # Feature structure:
│   │       ├── data/        # datasources/, models/, mappers/, repositories/
│   │       ├── domain/      # entities/, repositories/, usecases/
│   │       ├── presentation/# dialogs/, pages/, widgets/
│   │       └── providers/   # Riverpod providers
│   └── store/               # Store/business features
└── main.dart
```

## Code Style

- **Page width**: 90 chars | **Quotes**: Single only | **Trailing newline**: Required
- **ALWAYS**: `final` for params/locals, declare return types, const constructors
- **Imports order**: dart → package → relative

```dart
// Constructor first, unnamed before named, use super.key
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.value});
  final String value;
}

// child property ALWAYS last
Container(padding: EdgeInsets.all(8), child: Text('Content'))

// SizedBox for whitespace, not Container
const SizedBox(height: 16);
```

### Naming
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `wardrobe_item.dart` |
| Classes | PascalCase | `WardrobeRepository` |
| Providers | camelCaseProvider | `wardrobeItemsProvider` |
| Use Cases | VerbNoun | `GetWardrobeItems` |

## Error Handling (typed_result)

```dart
// Repository: return Result<T, String>
Future<Result<List<Item>, String>> getItems() async {
  try {
    final data = await _remote.fetch();
    return Ok(data);
  } catch (e) {
    AppLogger.error('Failed', e);
    return const Err('無法載入資料');  // Chinese user-facing message
  }
}

// Consume with pattern matching
switch (result) {
  case Ok(:final value): // success
  case Err(:final error): // error
}
```

## Riverpod Pattern

```dart
// providers.dart - one file per feature
final remoteProvider = Provider((ref) => RemoteDataSource(Supabase.instance.client));
final repoProvider = Provider((ref) => RepoImpl(remote: ref.watch(remoteProvider)));
final useCaseProvider = Provider((ref) => GetItems(ref.watch(repoProvider)));
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final result = await ref.watch(useCaseProvider)();
  if (result.isFailure) throw result.getError()!;
  return result.get()!;
});
```

## Widget Structure (HookConsumerWidget)

```dart
@override
Widget build(final BuildContext context, final WidgetRef ref) {
  // 1. Data providers → 2. Local state (hooks) → 3. Memoized
  // 4. Effects → 5. Theme → 6. Actions → 7. Widget helpers → 8. Return
  final dataAsync = ref.watch(dataProvider);
  final isLoading = useState(false);
  final colorScheme = Theme.of(context).colorScheme;
  
  Future<void> handleAction() async {
    isLoading.value = true;
    final result = await useCase();
    if (!context.mounted) return;  // REQUIRED after await
    isLoading.value = false;
  }
  
  return Scaffold(...);
}
```

## Logging (never use print)

```dart
AppLogger.debug('msg');  AppLogger.info('msg');  AppLogger.warning('msg');
AppLogger.error('msg', exception, stackTrace);  AppLogger.fatal('msg', e, st);
```

## Key Linter Rules (ENFORCED)
- `prefer_single_quotes` | `always_declare_return_types` | `prefer_final_locals/parameters`
- `prefer_const_constructors` | `sort_child_properties_last` | `avoid_print`
- `use_build_context_synchronously`: Check `context.mounted` after await

## Data Models (extend domain entities)

```dart
class ItemModel extends Item {
  const ItemModel({required super.id, required super.name});
  factory ItemModel.fromJson(final Map<String, dynamic> json) => ItemModel(
    id: json['id'] as String, name: json['name'] as String,
  );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

## Domain: Categories & Storage

| Category | Code | Storage Path |
|----------|------|--------------|
| 上衣 | `top` | `wardrobe/${userId}/${categoryCode}/${timestamp}.jpg` |
| 褲子 | `pants` | Avatars: `avatars/${userId}/avatar/${timestamp}.jpg` |
| 裙子 | `skirt` | |
| 外套 | `jacket` | |
| 鞋子 | `shoes` | |
| 配件 | `accessories` | |
| 其他 | `others` | |
