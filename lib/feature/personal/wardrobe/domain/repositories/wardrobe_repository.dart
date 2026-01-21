import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_category.dart';
import '../entities/wardrobe_item.dart';

abstract class WardrobeRepository {
  Future<Result<List<WardrobeItem>, String>> getWardrobeItems({
    final bool forceRefresh = false,
  });

  Future<Result<void, String>> uploadWardrobeItem({
    required final File image,
    required final WardrobeCategory category,
    final List<String> tags = const [],
  });

  Future<Result<void, String>> deleteWardrobeItem(final WardrobeItem item);

  Future<Result<File, String>> getWardrobeItemImage(final String imagePath);
}
