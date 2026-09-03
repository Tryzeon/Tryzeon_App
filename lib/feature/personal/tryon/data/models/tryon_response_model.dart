/// Server → Client wire response from the `tryon` edge function.
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

  final Map<String, dynamic>? usage;
}
