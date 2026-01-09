import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../repositories/wardrobe_repository.dart';

class GetWardrobeItemImage {
  GetWardrobeItemImage(this._repository);
  final WardrobeRepository _repository;

  Future<Result<File, String>> call(final String imagePath) =>
      _repository.getWardrobeItemImage(imagePath);
}
