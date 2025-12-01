import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/login/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/login/presentation/pages/personal_login_page.dart';
import 'package:tryzeon/feature/login/presentation/pages/store_login_page.dart';

void main() {
  testWidgets('LoginPage renders correctly and navigates', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Allow animations to complete
    await tester.pumpAndSettle();

    // Check if header text is present
    expect(find.text('Tryzeon'), findsOneWidget);
    expect(find.text('Choose your identity'), findsOneWidget);

    // Check if buttons are present
    expect(find.text('User Login'), findsOneWidget);
    expect(find.text('Store Login'), findsOneWidget);

    // Test Navigation to Personal Login
    await tester.tap(find.text('User Login'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonalLoginPage), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Test Navigation to Store Login
    await tester.tap(find.text('Store Login'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreLoginPage), findsOneWidget);
  });
}
