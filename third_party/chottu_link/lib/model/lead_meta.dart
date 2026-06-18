/// Flutter representation of Android `ChottuLink.LeadMeta`.
class LeadMeta {
  final String? eventName;
  final Map<String, dynamic>? metadata;

  const LeadMeta({
    this.eventName,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      if (eventName != null) 'eventName': eventName,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
