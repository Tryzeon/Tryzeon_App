import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/home/presentation/pages/home_page.dart';

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

  testWidgets('StoreHomePage renders structure and empty state after load', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StoreHomePage()));

    // Don't pump here if we want to catch initial state, or just check final state.
    // If logic is fast, loading might be over.

    // Wait for load (failure)
    await tester.pumpAndSettle();

    // Clear notifications
    await tester.pump(const Duration(seconds: 11));

    // After failure, products list is empty.
    // Check if it shows empty state or at least header
    expect(find.text('店家後台'), findsOneWidget);

    // "還沒有商品" should be visible if products is empty
    expect(find.text('還沒有商品'), findsOneWidget);
  });
}
