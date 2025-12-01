import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase for tests
    await Supabase.initialize(
      url: 'https://vshrdjgrweuuxtdqsevk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzaHJkamdyd2V1dXh0ZHFzZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTE0NzUsImV4cCI6MjA3NDM4NzQ3NX0.k-l5AN8VjVapOalYtMxXETf-Ijxq6X5qEqmajxNMLvM',
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  });

  testWidgets('PersonalEntry renders bottom navigation', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalEntry()));

    // Allow initial build
    await tester.pump();

    // Check for text labels
    expect(find.text('社群'), findsOneWidget);
    expect(find.text('試衣間'), findsOneWidget);
    expect(find.text('首頁'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('個人'), findsOneWidget);

    // Clear any pending timers (notifications from child pages)
    await tester.pump(const Duration(seconds: 11));
  });
}
