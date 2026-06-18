import 'dart:async';

import 'package:flutter/foundation.dart';

/// Converts a [Stream] into a [Listenable] for GoRouter's
/// refreshListenable parameter.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(final Stream<dynamic> stream) {
    _subscription = stream.listen((final _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  /// Manually triggers GoRouter's redirect re-evaluation.
  void refresh() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
