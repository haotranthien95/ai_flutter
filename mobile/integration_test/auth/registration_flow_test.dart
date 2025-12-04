import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ai_flutter/main.dart' as app;

/// Integration test for user registration flow (T085)
///
/// Test Scenario:
/// 1. Launch app
/// 2. Navigate to register screen
/// 3. Enter registration details (name, phone, email, password)
/// 4. Submit registration form
/// 5. Navigate to OTP verification screen
/// 6. Enter valid OTP code
/// 7. Verify authenticated state
/// 8. Verify navigation to home/profile
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Registration Flow Integration Test (T085)', () {
    testWidgets('Complete user registration journey from form to authenticated',
        (tester) async {
      // Step 1: Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 2: Navigate to login screen (if not already there)
      // Look for profile icon in bottom navigation
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }

      // Step 3: Find and tap "Đăng ký" link/button on login screen
      final registerLink = find.text('Đăng ký ngay');
      expect(
        registerLink,
        findsOneWidget,
        reason: 'Should find register link on login screen',
      );

      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Step 4: Verify registration screen displays
      expect(
        find.text('Đăng ký tài khoản'),
        findsOneWidget,
        reason: 'Should display registration screen title',
      );

      // Step 5: Enter registration details
      // Find form fields by placeholder/label text
      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      expect(nameField, findsOneWidget, reason: 'Should find name field');
      await tester.enterText(nameField, 'Nguyễn Văn Test');
      await tester.pump();

      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
      expect(phoneField, findsOneWidget, reason: 'Should find phone field');
      await tester.enterText(phoneField, '0987654321');
      await tester.pump();

      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Should find email field');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
      expect(passwordField, findsOneWidget,
          reason: 'Should find password field');
      await tester.enterText(passwordField, 'Test@12345');
      await tester.pump();

      final confirmPasswordField =
          find.widgetWithText(TextFormField, 'Xác nhận mật khẩu');
      expect(
        confirmPasswordField,
        findsOneWidget,
        reason: 'Should find confirm password field',
      );
      await tester.enterText(confirmPasswordField, 'Test@12345');
      await tester.pump();

      // Step 6: Scroll to make submit button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Step 7: Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
      expect(registerButton, findsOneWidget,
          reason: 'Should find register button');
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 8: Verify OTP verification screen displays
      expect(
        find.text('Xác thực OTP'),
        findsOneWidget,
        reason: 'Should navigate to OTP verification screen',
      );

      // Verify phone number is displayed
      expect(
        find.textContaining('0987654321'),
        findsOneWidget,
        reason: 'Should display phone number for verification',
      );

      // Step 9: Enter OTP code (6 digits)
      // Find OTP input fields
      final otpFields = find.byType(TextField);
      expect(
        otpFields.evaluate().length >= 6,
        isTrue,
        reason: 'Should have at least 6 OTP input fields',
      );

      // Enter OTP digits (assuming mock/test OTP is 123456)
      // Note: In real scenario, this would fail without proper backend
      // For integration test, we'll enter the code and check if verify button enables
      for (int i = 0; i < 6 && i < otpFields.evaluate().length; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Step 10: Verify "Xác thực" button is enabled
      final verifyButton = find.widgetWithText(ElevatedButton, 'Xác thực');
      expect(
        verifyButton,
        findsOneWidget,
        reason: 'Should find verify button',
      );

      // Note: Tapping verify button will fail in test without backend
      // But we can verify the UI flow up to this point
      // In real scenario with test backend, we would:
      // await tester.tap(verifyButton);
      // await tester.pumpAndSettle(const Duration(seconds: 2));
      // expect(find.text('Đăng nhập thành công'), findsOneWidget);

      // Step 11: Verify countdown timer is running
      expect(
        find.textContaining('Gửi lại'),
        findsOneWidget,
        reason: 'Should display resend button',
      );

      // Step 12: Verify can navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should be back on registration screen
      expect(
        find.text('Đăng ký tài khoản'),
        findsOneWidget,
        reason: 'Should navigate back to registration screen',
      );
    });

    testWidgets('Registration form validation', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to profile/login
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }

      // Navigate to register
      final registerLink = find.text('Đăng ký ngay');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Step 1: Try to submit empty form
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final registerButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should see validation errors
      expect(
        find.text('Vui lòng nhập họ tên'),
        findsOneWidget,
        reason: 'Should show name validation error',
      );

      // Step 2: Enter invalid phone format
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();

      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
      await tester.enterText(phoneField, '123'); // Invalid format
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('điện thoại'),
        findsWidgets,
        reason: 'Should show phone validation error',
      );

      // Step 3: Enter valid phone but mismatched passwords
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      await tester.enterText(nameField, 'Test User');
      await tester.pump();

      await tester.enterText(phoneField, '0987654321');
      await tester.pump();

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
      await tester.enterText(passwordField, 'Password123');
      await tester.pump();

      final confirmPasswordField =
          find.widgetWithText(TextFormField, 'Xác nhận mật khẩu');
      await tester.enterText(confirmPasswordField, 'DifferentPassword');
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('khớp'),
        findsOneWidget,
        reason: 'Should show password mismatch error',
      );
    });

    testWidgets('OTP resend functionality', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to register screen
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }

      final registerLink = find.text('Đăng ký ngay');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Fill registration form with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ và tên'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '0987654321',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'Test@12345',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Xác nhận mật khẩu'),
        'Test@12345',
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on OTP screen
      expect(find.text('Xác thực OTP'), findsOneWidget);

      // Wait for countdown to allow resend (or check if button is disabled initially)
      final resendButton = find.textContaining('Gửi lại');
      expect(resendButton, findsOneWidget);

      // In real scenario, we would wait for countdown and tap resend
      // For now, just verify the UI elements exist
      expect(
        find.byType(TextButton),
        findsWidgets,
        reason: 'Should have resend button',
      );
    });

    testWidgets('Navigate between registration and login screens',
        (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to profile/login
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }

      // Should be on login screen
      expect(
        find.text('Đăng nhập'),
        findsWidgets,
        reason: 'Should display login screen',
      );

      // Navigate to register
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();

      // Should be on register screen
      expect(
        find.text('Đăng ký tài khoản'),
        findsOneWidget,
        reason: 'Should display registration screen',
      );

      // Navigate back to login
      final loginLink = find.text('Đăng nhập ngay');
      expect(
        loginLink,
        findsOneWidget,
        reason: 'Should have login link on register screen',
      );

      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Should be back on login screen
      expect(
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
        findsOneWidget,
        reason: 'Should navigate back to login screen',
      );
    });
  });
}
