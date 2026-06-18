/// Flutter representation of Android `ChottuLink.ConversionMeta`.
class ConversionMeta {
  final double revenue;
  final String? currency;
  final String? eventName;
  final String? productId;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  const ConversionMeta({
    required this.revenue,
    this.currency,
    this.eventName,
    this.productId,
    this.transactionId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'revenue': revenue,
      if (currency != null) 'currency': currency,
      if (eventName != null) 'eventName': eventName,
      if (productId != null) 'productId': productId,
      if (transactionId != null) 'transactionId': transactionId,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
