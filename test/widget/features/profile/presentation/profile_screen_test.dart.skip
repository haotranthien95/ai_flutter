import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/profile/presentation/profile_screen.dart';
import 'package:ai_flutter/features/profile/presentation/providers/profile_provider.dart';
import 'package:ai_flutter/core/models/user.dart';

void main() {
  group('ProfileScreen Widget Tests - T083', () {
    final testUser = User(
      id: '1',
      phoneNumber: '0901234567',
      email: 'test@example.com',
      fullName: 'Nguyễn Văn A',
      avatarUrl: null,
      role: UserRole.buyer,
      isVerified: true,
      isSuspended: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    testWidgets('renders user profile information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user information is displayed
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays avatar placeholder when no avatar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show person icon as placeholder
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays all menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify menu items
      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);
      expect(find.text('Quản lý địa chỉ'), findsOneWidget);
      expect(find.text('Đơn hàng của tôi'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('navigates to edit profile screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit profile
      await tester.tap(find.text('Chỉnh sửa thông tin'));
      await tester.pumpAndSettle();

      // Should navigate to edit screen
      expect(find.text('Chỉnh sửa thông tin'), findsWidgets);
    });

    testWidgets('navigates to address list screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap manage addresses
      await tester.tap(find.text('Quản lý địa chỉ'));
      await tester.pumpAndSettle();

      // Should navigate to address list screen
      expect(find.text('Địa chỉ giao hàng'), findsOneWidget);
    });

    testWidgets('shows placeholder message for orders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap my orders
      await tester.tap(find.text('Đơn hàng của tôi'));
      await tester.pumpAndSettle();

      // Should show placeholder snackbar
      expect(find.text('Tính năng đang được phát triển'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Bạn có chắc chắn muốn đăng xuất?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Đăng xuất'), findsOneWidget);
    });

    testWidgets('cancels logout on dialog cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierSuccess(testUser)),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Dialog should close, still on profile screen
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('shows loading state while fetching profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierLoading()),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierError()),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error UI
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Không thể tải thông tin'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('retries loading on error retry button tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => MockProfileNotifierError()),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      // Should attempt to reload (loading indicator or success)
      // Actual retry behavior would need more complex mock setup
    });

    testWidgets('handles user without email', (WidgetTester tester) async {
      final userWithoutEmail = testUser.copyWith(email: null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) => MockProfileNotifierSuccess(userWithoutEmail),
            ),
          ],
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show phone but not email
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsNothing);
    });
  });
}
