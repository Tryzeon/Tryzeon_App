/// Represents an error that occurred within the ChottuLink SDK.
class ChottuLinkError {
  /// A short code indicating the type of error.
  String? errorCode;

  /// A human-readable message describing the error.
  String? message;

  /// A more detailed description of the error and how to resolve it.
  String? description;

  /// Creates an instance of [ChottuLinkError].
  ChottuLinkError({this.errorCode, this.message, this.description});
}
