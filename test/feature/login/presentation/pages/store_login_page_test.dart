import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/login/presentation/pages/store_login_page.dart';

void main() {
  testWidgets('StoreLoginPage renders correctly', (final WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoreLoginPage()));

    // Check header
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Start managing your store'), findsOneWidget);

    // Check buttons
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    // Check back button
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
