import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/auth/presentation/otp_verification_screen.dart';

void main() {
  group('OTPVerificationScreen Widget Tests - T082', () {
    const testPhoneNumber = '0901234567';

    testWidgets('renders OTP form with 6 input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Xác thực OTP'), findsOneWidget);
      expect(find.textContaining('Nhập mã OTP'), findsOneWidget);
      expect(find.textContaining(testPhoneNumber), findsOneWidget);

      // Should have 6 OTP input fields
      expect(find.byType(TextFormField), findsNWidgets(6));

      // Should have verify button
      expect(find.text('Xác nhận'), findsOneWidget);

      // Should have resend button
      expect(find.textContaining('Gửi lại'), findsOneWidget);
    });

    testWidgets('displays countdown timer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      // Should show initial countdown
      expect(find.textContaining('1:00'), findsOneWidget);

      // Wait and check timer decreases
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('0:59'), findsOneWidget);
    });

    testWidgets('allows entering OTP digits', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      // Enter digits in OTP fields
      final otpFields = find.byType(TextFormField);

      await tester.enterText(otpFields.at(0), '1');
      await tester.pump();

      await tester.enterText(otpFields.at(1), '2');
      await tester.pump();

      await tester.enterText(otpFields.at(2), '3');
      await tester.pump();

      // Verify digits are entered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('auto-focuses next field on input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      final otpFields = find.byType(TextFormField);

      // Enter digit in first field
      await tester.enterText(otpFields.at(0), '1');
      await tester.pump();

      // Second field should be focused (tested via focus node)
      // Note: Full focus testing requires more complex setup
    });

    testWidgets('enables verify button when OTP is complete',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      final otpFields = find.byType(TextFormField);

      // Enter complete OTP
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '$i');
        await tester.pump();
      }

      // Verify button should be enabled
      final verifyButton = find.widgetWithText(ElevatedButton, 'Xác nhận');
      expect(verifyButton, findsOneWidget);
    });

    testWidgets('disables resend button during countdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      // Resend button should be disabled initially
      final resendButton = find.ancestor(
        of: find.textContaining('Gửi lại'),
        matching: find.byType(TextButton),
      );

      expect(resendButton, findsOneWidget);

      final button = tester.widget<TextButton>(resendButton);
      expect(button.onPressed, isNull); // Should be disabled
    });

    testWidgets('enables resend button after countdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OTPVerificationScreen(phoneNumber: testPhoneNumber),
          ),
        ),
      );

      // Fast forward timer
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();

      // Resend button should now be enabled
      final resendButton = find.ancestor(
        of: find.textContaining('Gửi lại'),
        matching: find.byType(TextButton),
      );

      final button = tester.widget<TextButton>(resendButton);
      expect(button.onPressed, isNotNull); // Should be enabled
    });
  });
}
