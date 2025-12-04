import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/home/presentation/pages/settings/data/profile_service.dart';

void main() {
  group('StoreProfile', () {
    final profile = StoreProfile(
      storeId: 'store_123',
      name: 'Test Store',
      address: '123 Main St',
      logoPath: 'path/to/logo.png',
    );

    test('fromJson parses valid JSON correctly', () {
      final json = {
        'store_id': 'store_123',
        'name': 'Test Store',
        'address': '123 Main St',
        'logo_path': 'path/to/logo.png',
      };

      final result = StoreProfile.fromJson(json);

      expect(result.storeId, 'store_123');
      expect(result.name, 'Test Store');
      expect(result.address, '123 Main St');
      expect(result.logoPath, 'path/to/logo.png');
    });

    test('toJson converts object to valid JSON', () {
      final json = profile.toJson();

      expect(json['store_id'], 'store_123');
      expect(json['name'], 'Test Store');
      expect(json['address'], '123 Main St');
      expect(json['logo_path'], 'path/to/logo.png');
    });

    test('copyWith creates new instance with updated values', () {
      final copy = profile.copyWith(name: 'New Store Name');

      expect(copy.storeId, profile.storeId);
      expect(copy.name, 'New Store Name');
      expect(copy.address, profile.address);
      expect(copy.logoPath, profile.logoPath);

      final copyLogo = profile.copyWith(logoPath: 'new/path.png');
      expect(copyLogo.logoPath, 'new/path.png');
    });

    test('getDirtyFields detects changes correctly', () {
      // Case 1: No changes
      expect(profile.getDirtyFields(profile), isEmpty);

      // Case 2: Name changed
      final nameChanged = profile.copyWith(name: 'New Name');
      expect(profile.getDirtyFields(nameChanged), {'name': 'New Name'});

      // Case 3: Address changed
      final addressChanged = profile.copyWith(address: '456 Other St');
      expect(profile.getDirtyFields(addressChanged), {'address': '456 Other St'});

      // Case 4: Logo path changed
      final logoChanged = profile.copyWith(logoPath: 'new/logo.png');
      expect(profile.getDirtyFields(logoChanged), {'logo_path': 'new/logo.png'});

      // Case 5: Multiple changes
      final multiChanged = profile.copyWith(name: 'New Name', address: 'New Address');
      final diff = profile.getDirtyFields(multiChanged);
      expect(diff['name'], 'New Name');
      expect(diff['address'], 'New Address');
      expect(diff.containsKey('logo_path'), false);
    });
  });
}
