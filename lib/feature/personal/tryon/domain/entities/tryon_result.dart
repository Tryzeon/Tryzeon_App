import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'tryon_mode.dart';

part 'tryon_result.freezed.dart';

@freezed
sealed class TryonResult with _$TryonResult {
  const factory TryonResult({
    required final String id,
    required final TryonMode mode,
    final String? imageUrl,
    final String? videoUrl,
    final DailyUsage? usage,
  }) = _TryonResult;
}
