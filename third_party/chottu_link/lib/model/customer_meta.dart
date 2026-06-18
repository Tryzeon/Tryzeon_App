/// Flutter representation of Android `ChottuLink.CustomerMeta`.
///
/// This is a lightweight container that is converted to/from a platform-channel
/// argument map.
class CustomerMeta {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? emailSha256;
  final String? phoneSha256;

  const CustomerMeta({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.emailSha256,
    this.phoneSha256,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (emailSha256 != null) 'emailSha256': emailSha256,
      if (phoneSha256 != null) 'phoneSha256': phoneSha256,
    };
  }
}

