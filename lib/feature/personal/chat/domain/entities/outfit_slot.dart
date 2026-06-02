import 'package:freezed_annotation/freezed_annotation.dart';

part 'outfit_slot.freezed.dart';

@freezed
sealed class OutfitSlot with _$OutfitSlot {
  const factory OutfitSlot({
    required final String slotLabel,
    required final String categoryName,
    @Default([]) final List<String> tags,
    required final String reason,
  }) = _OutfitSlot;
}
