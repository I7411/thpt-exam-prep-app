import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thpt_exam_prep_app/widgets/app_password_field.dart';

void main() {
  testWidgets('password field toggles visibility and auto-hides', (tester) async {
    final controller = TextEditingController(text: 'secret123');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPasswordField(
            controller: controller,
            label: 'Password',
            hintText: 'Enter password',
            autoHideDuration: const Duration(milliseconds: 50),
          ),
        ),
      ),
    );

    TextFormField field() => tester.widget(find.byType(TextFormField));

    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(field().obscureText, isFalse);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(field().obscureText, isTrue);
    expect(controller.text, 'secret123');
  });

  testWidgets('multiple password fields keep independent visibility state', (
    tester,
  ) async {
    final first = TextEditingController(text: 'first');
    final second = TextEditingController(text: 'second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppPasswordField(
                controller: first,
                label: 'First',
                hintText: 'First password',
              ),
              AppPasswordField(
                controller: second,
                label: 'Second',
                hintText: 'Second password',
              ),
            ],
          ),
        ),
      ),
    );

    TextFormField fieldAt(int index) {
      return tester.widget(find.byType(TextFormField).at(index));
    }

    await tester.tap(find.byTooltip('Show password').first);
    await tester.pumpAndSettle();

    expect(fieldAt(0).obscureText, isFalse);
    expect(fieldAt(1).obscureText, isTrue);
  });
}
