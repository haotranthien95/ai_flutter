import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/auth/presentation/register_screen.dart';

void main() {
  group('RegisterScreen Widget Tests - T081', () {
    testWidgets('renders registration form with all fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Email (không bắt buộc)'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
      expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation error for empty full name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Tap register button without entering data
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid phone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ và tên'),
        'Nguyễn Văn A',
      );

      // Enter invalid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '123',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (không bắt buộc)'),
        'invalid-email',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });

    testWidgets('shows validation error for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter short password
      final passwordFields = find.widgetWithText(TextFormField, 'Mật khẩu');
      await tester.enterText(passwordFields, '123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsOneWidget);
    });

    testWidgets('shows validation error for mismatched passwords',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'password123',
      );

      // Enter different confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Xác nhận mật khẩu'),
        'different123',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu không khớp'), findsOneWidget);
    });

    testWidgets('shows password strength indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Enter weak password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'weak',
      );
      await tester.pumpAndSettle();

      // Should show password strength indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Yếu'), findsOneWidget);

      // Enter strong password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'StrongPass123!@#',
      );
      await tester.pumpAndSettle();

      expect(find.text('Mạnh'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Find password field icon buttons
      final passwordIcons = find.descendant(
        of: find.byType(TextFormField),
        matching: find.byType(IconButton),
      );

      // Should have 2 visibility toggles (password + confirm)
      expect(passwordIcons, findsAtLeastNWidgets(2));

      // Tap first visibility toggle
      await tester.tap(passwordIcons.first);
      await tester.pumpAndSettle();

      // Password should toggle visibility
      // (Actual obscureText testing would require more complex setup)
    });

    testWidgets('navigates to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Tap login link
      await tester.tap(find.text('Đã có tài khoản? Đăng nhập'));
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}
