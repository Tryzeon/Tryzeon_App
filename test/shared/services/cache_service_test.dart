import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveJSON saves map as json string', () async {
      final data = {'key': 'value', 'count': 1};
      await CacheService.saveJSON('test_json', data);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('test_json'), '{"key":"value","count":1}');
    });

    test('loadJSON loads map correctly', () async {
      SharedPreferences.setMockInitialValues({'test_json': '{"key":"value","count":1}'});

      final data = await CacheService.loadJSON('test_json');
      expect(data, {'key': 'value', 'count': 1});
    });

    test('loadJSON returns null if not found', () async {
      final data = await CacheService.loadJSON('non_existent');
      expect(data, null);
    });

    test('saveList saves list as json string', () async {
      final list = ['a', 'b', 'c'];
      await CacheService.saveList('test_list', list);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('test_list'), '["a","b","c"]');
    });

    test('loadList loads list correctly', () async {
      SharedPreferences.setMockInitialValues({'test_list': '["a","b","c"]'});

      final list = await CacheService.loadList('test_list');
      expect(list, ['a', 'b', 'c']);
    });

    test('clearCache removes the key', () async {
      SharedPreferences.setMockInitialValues({'test_key': 'some value'});

      await CacheService.clearCache('test_key');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('test_key'), false);
    });
  });
}
