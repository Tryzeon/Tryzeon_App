/// Server → Client wire response from the `tryon` edge function. Decodes the
/// raw row inside `data/`; the repository maps it to a `TryonResult`.
class TryonResponseModel {
  const TryonResponseModel({this.imageUrl, this.videoUrl, this.usage});

  factory TryonResponseModel.fromJson(final Map<String, dynamic> json) {
    return TryonResponseModel(
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      usage: json['usage'] as Map<String, dynamic>?,
    );
  }

  final String? imageUrl;
  final String? videoUrl;

  /// Raw usage snapshot; parsed into a `DailyUsage` by the repository.
  final Map<String, dynamic>? usage;
}
