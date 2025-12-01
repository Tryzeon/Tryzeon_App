import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (final MethodCall methodCall) async {
          return '.';
        },
      );
    });

    test('saveToCache and loadFromCache work for Map', () async {
      final data = {'key': 'value', 'count': 1};
      await CacheService.saveToCache('test_map', data);

      final loadedData = await CacheService.loadFromCache('test_map');
      expect(loadedData, data);
    });

    test('saveToCache and loadFromCache work for List', () async {
      final list = ['a', 'b', 'c'];
      await CacheService.saveToCache('test_list', list);

      final loadedList = await CacheService.loadFromCache('test_list');
      expect(loadedList, list);
    });

    test('saveToCache and loadFromCache work for String', () async {
      const str = 'test string';
      await CacheService.saveToCache('test_string', str);

      final loadedStr = await CacheService.loadFromCache('test_string');
      expect(loadedStr, str);
    });

    test('loadFromCache returns null if key does not exist', () async {
      final data = await CacheService.loadFromCache('non_existent');
      expect(data, null);
    });

    test('deleteCache removes the item', () async {
      await CacheService.saveToCache('to_delete', 'value');
      await CacheService.deleteCache('to_delete');

      final data = await CacheService.loadFromCache('to_delete');
      expect(data, null);
    });

    test('deleteCache removes all items (data)', () async {
      await CacheService.saveToCache('item1', 'value1');
      await CacheService.saveToCache('item2', 'value2');

      try {
        await CacheService.clearCache();
      } catch (_) {
        // Ignore DefaultCacheManager errors in test environment
      }

      expect(await CacheService.loadFromCache('item1'), null);
      expect(await CacheService.loadFromCache('item2'), null);
    });
  });
}
