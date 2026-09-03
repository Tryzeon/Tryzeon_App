import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] to GoRouter's `refreshListenable`.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(final Stream<dynamic> stream) {
    _subscription = stream.listen((final _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
