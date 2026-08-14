import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_keyboard_dismisser.dart';

void main() {
  final focusNode = FocusNode();

  Widget buildSubject() {
    return MaterialApp(
      home: AppKeyboardDismisser(
        child: Scaffold(
          body: Column(
            children: [
              // A numeric field has no return key on iOS, so tapping outside is
              // the only way out.
              TextField(focusNode: focusNode, keyboardType: TextInputType.number),
              const SizedBox(height: 400, child: Text('outside')),
            ],
          ),
        ),
      ),
    );
  }

  tearDownAll(focusNode.dispose);

  testWidgets('unfocuses when the tap lands outside the field', (final tester) async {
    await tester.pumpWidget(buildSubject());

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('outside'));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('keeps focus when the pointer is dragged past the slop', (
    final tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    final gesture = await tester.startGesture(tester.getCenter(find.text('outside')));
    await gesture.moveBy(const Offset(0, -(kTouchSlop + 20)));
    await gesture.up();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });

  // Control: proves the tests above measure this widget and not some default.
  testWidgets('without the wrapper the framework keeps the keyboard open', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focusNode, keyboardType: TextInputType.number),
              const SizedBox(height: 400, child: Text('outside')),
            ],
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    await tester.tap(find.text('outside'));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('keeps focus when the tap lands inside the field', (final tester) async {
    await tester.pumpWidget(buildSubject());

    focusNode.requestFocus();
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });
}
