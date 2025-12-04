import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/auth/presentation/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests - T080', () {
    testWidgets('renders login form with all fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation error for empty phone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap login button without entering data
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid phone format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter invalid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '123456',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter valid phone but no password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '0901234567',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Find password field
      final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
      expect(passwordField, findsOneWidget);

      // Find visibility toggle icon
      final visibilityIcon = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );

      // Initially password should be obscured
      TextField textField = tester.widget(find.byType(TextField).last);
      expect(textField.obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // Password should now be visible
      textField = tester.widget(find.byType(TextField).last);
      expect(textField.obscureText, isFalse);
    });

    testWidgets('navigates to forgot password screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap forgot password link
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      // Should navigate to forgot password screen
      expect(find.text('Quên mật khẩu'), findsOneWidget);
    });

    testWidgets('navigates to register screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap register link
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();

      // Should navigate to register screen
      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    });
  });
}
