import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tryzeon/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock shared preferences
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase for tests
    await Supabase.initialize(
      url: 'https://vshrdjgrweuuxtdqsevk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzaHJkamdyd2V1dXh0ZHFzZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTE0NzUsImV4cCI6MjA3NDM4NzQ3NX0.k-l5AN8VjVapOalYtMxXETf-Ijxq6X5qEqmajxNMLvM',
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  });

  testWidgets('App smoke test', (final WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Tryzeon());

    // Verify that the app builds without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
