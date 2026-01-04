import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryOnRepository {
  Future<Result<TryonResult, String>> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
  });
}
