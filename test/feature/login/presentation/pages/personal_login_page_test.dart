import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/login/presentation/pages/personal_login_page.dart';

void main() {
  testWidgets('PersonalLoginPage renders correctly', (final WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalLoginPage()));

    // Check header
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Ready to try on some new looks?'), findsOneWidget);

    // Check buttons
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    // Check back button
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
