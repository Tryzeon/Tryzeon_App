import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';

enum CacheEntryStatus { hasData, empty, absent }

class CacheEntryLocalDataSource {
  CacheEntryLocalDataSource(this._isarService);

  final IsarService _isarService;

  Future<CacheEntryStatus?> getEntryStatus(
    final String cacheKey, {
    final Duration? staleDuration,
  }) async {
    final isar = await _isarService.db;
    final entry = await isar.cacheEntrys.getByCacheKey(cacheKey);
    if (entry == null) return null;

    if (staleDuration != null) {
      final age = DateTime.now().difference(entry.fetchedAt);
      if (age > staleDuration) return null;
    }

    return CacheEntryStatus.values.byName(entry.status);
  }

  Future<void> markHasData(final String cacheKey) {
    return _saveEntry(cacheKey, CacheEntryStatus.hasData);
  }

  Future<void> markEmpty(final String cacheKey) {
    return _saveEntry(cacheKey, CacheEntryStatus.empty);
  }

  Future<void> markListState(final String cacheKey, {required final bool isEmpty}) {
    return _saveEntry(
      cacheKey,
      isEmpty ? CacheEntryStatus.empty : CacheEntryStatus.hasData,
    );
  }

  Future<void> _saveEntry(final String cacheKey, final CacheEntryStatus status) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final entry = CacheEntry()
        ..cacheKey = cacheKey
        ..status = status.name
        ..fetchedAt = DateTime.now();
      await isar.cacheEntrys.putByCacheKey(entry);
    });
  }
}
