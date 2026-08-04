import 'package:tryzeon/feature/auth/domain/entities/login_provider.dart';

extension LoginProviderDisplay on LoginProvider {
  String get label => switch (this) {
    LoginProvider.apple => 'Apple',
    LoginProvider.google => 'Google',
    LoginProvider.line => 'LINE',
  };

  String get logoAsset => 'assets/images/logo/$label.svg';
}
