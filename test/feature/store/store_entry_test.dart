import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/store_entry.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://vshrdjgrweuuxtdqsevk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzaHJkamdyd2V1dXh0ZHFzZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTE0NzUsImV4cCI6MjA3NDM4NzQ3NX0.k-l5AN8VjVapOalYtMxXETf-Ijxq6X5qEqmajxNMLvM',
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  });

  testWidgets('StoreEntry renders loading then potentially onboarding', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StoreEntry()));

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for async checks (will fail) and notifications
    // Since it fails, it likely stays on Onboarding or whatever default is.
    await tester.pumpAndSettle();

    // Clear timers
    await tester.pump(const Duration(seconds: 11));
  });
}
