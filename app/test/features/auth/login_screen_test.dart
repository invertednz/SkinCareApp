import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/features/auth/login_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('shows disabled social buttons and hint text', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    final googleBtn = find.widgetWithText(OutlinedButton, 'Continue with Google');
    final appleBtn = find.widgetWithText(OutlinedButton, 'Continue with Apple');

    expect(googleBtn, findsOneWidget);
    expect(appleBtn, findsOneWidget);

    final googleWidget = tester.widget<OutlinedButton>(googleBtn);
    final appleWidget = tester.widget<OutlinedButton>(appleBtn);
    expect(googleWidget.onPressed, isNull);
    expect(appleWidget.onPressed, isNull);

    expect(find.text('Social sign-in coming soon'), findsOneWidget);
  }, skip: true);

  testWidgets('validates email and password, disables terms/privacy when missing', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    final email = find.byKey(const Key('emailField'));
    final password = find.byKey(const Key('passwordField'));
    final submit = find.byKey(const Key('submitButton'));

    // Submit empty form
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Enter invalid email and short password
    await tester.enterText(email, 'invalid');
    await tester.enterText(password, '123');
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);

    final termsBtn = tester.widget<TextButton>(find.byKey(const Key('termsLink')));
    final privacyBtn = tester.widget<TextButton>(find.byKey(const Key('privacyLink')));
    expect(termsBtn.onPressed, isNull);
    expect(privacyBtn.onPressed, isNull);
  }, skip: true);
}
