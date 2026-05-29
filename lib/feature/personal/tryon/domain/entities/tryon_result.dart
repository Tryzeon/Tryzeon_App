import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'tryon_mode.dart';

part 'tryon_result.freezed.dart';

@freezed
sealed class TryonResult with _$TryonResult {
  const factory TryonResult({
    required final String id,
    final String? imageUrl,
    final String? videoUrl,
    final DailyUsage? usage,
    @Default(false) final bool isLoading,
    @Default(TryOnMode.image) final TryOnMode mode,
  }) = _TryonResult;
}
