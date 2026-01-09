import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_category.dart';
import '../repositories/wardrobe_repository.dart';

class UploadWardrobeItem {
  UploadWardrobeItem(this._repository);
  final WardrobeRepository _repository;

  Future<Result<void, String>> call({
    required final File image,
    required final WardrobeCategory category,
    final List<String> tags = const [],
  }) => _repository.uploadWardrobeItem(image: image, category: category, tags: tags);
}
