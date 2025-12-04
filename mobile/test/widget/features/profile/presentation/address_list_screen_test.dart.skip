import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/profile/presentation/address_list_screen.dart';
import 'package:ai_flutter/features/profile/presentation/providers/profile_provider.dart';
import 'package:ai_flutter/core/models/address.dart';

void main() {
  group('AddressListScreen Widget Tests - T084', () {
    final testAddresses = [
      Address(
        id: '1',
        userId: 'user1',
        recipientName: 'Nguyễn Văn A',
        phoneNumber: '0901234567',
        streetAddress: '123 Đường ABC',
        ward: 'Phường 1',
        district: 'Quận 1',
        city: 'TP. Hồ Chí Minh',
        isDefault: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Address(
        id: '2',
        userId: 'user1',
        recipientName: 'Nguyễn Văn B',
        phoneNumber: '0987654321',
        streetAddress: '456 Đường XYZ',
        ward: 'Phường 2',
        district: 'Quận 2',
        city: 'TP. Hồ Chí Minh',
        isDefault: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    testWidgets('renders address list screen title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Địa chỉ giao hàng'), findsOneWidget);
    });

    testWidgets('displays list of addresses', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify addresses are displayed
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Nguyễn Văn B'), findsOneWidget);
      expect(find.text('123 Đường ABC'), findsOneWidget);
      expect(find.text('456 Đường XYZ'), findsOneWidget);
    });

    testWidgets('shows default badge on default address',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show default badge on first address
      expect(find.text('Mặc định'), findsOneWidget);
    });

    testWidgets('displays action buttons for each address',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show action buttons
      expect(find.text('Đặt mặc định'), findsOneWidget); // Only for non-default
      expect(find.text('Sửa'), findsNWidgets(2)); // For both addresses
      expect(find.text('Xóa'), findsNWidgets(2)); // For both addresses
    });

    testWidgets('shows FAB for adding new address',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Thêm địa chỉ'), findsOneWidget);
    });

    testWidgets('navigates to add address form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should navigate to address form
      expect(find.text('Thêm địa chỉ'), findsWidgets);
    });

    testWidgets('navigates to edit address form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.text('Sửa').first);
      await tester.pumpAndSettle();

      // Should navigate to edit form
      expect(find.text('Sửa địa chỉ'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.text('Xóa').first);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Xóa địa chỉ'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn xóa địa chỉ'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Xóa'), findsOneWidget);
    });

    testWidgets('shows empty state when no addresses',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess([]),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.text('Chưa có địa chỉ nào'), findsOneWidget);
      expect(find.text('Thêm địa chỉ giao hàng của bạn'), findsOneWidget);
    });

    testWidgets('shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierLoading(),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierError(),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error UI
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Không thể tải danh sách địa chỉ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('displays formatted phone numbers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show formatted phone numbers
      expect(find.textContaining('0901 234 567'), findsOneWidget);
      expect(find.textContaining('0987 654 321'), findsOneWidget);
    });

    testWidgets('displays full address details', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAddressesProvider.overrideWith(
              (ref) => MockAddressNotifierSuccess(testAddresses),
            ),
          ],
          child: MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show full address components
      expect(find.textContaining('123 Đường ABC'), findsOneWidget);
      expect(find.textContaining('Phường 1'), findsOneWidget);
      expect(find.textContaining('Quận 1'), findsOneWidget);
      expect(find.textContaining('TP. Hồ Chí Minh'), findsOneWidget);
    });
  });
}

/// Mock AddressNotifier with success state
class MockAddressNotifierSuccess
    extends StateNotifier<AsyncValue<List<Address>>> {
  MockAddressNotifierSuccess(List<Address> addresses)
      : super(AsyncValue.data(addresses));

  Future<void> loadAddresses() async {}

  Future<bool> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    return true;
  }

  Future<bool> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
  }) async {
    return true;
  }

  Future<bool> deleteAddress(String addressId) async {
    return true;
  }

  Future<bool> setDefaultAddress(String addressId) async {
    return true;
  }
}

/// Mock AddressNotifier with loading state
class MockAddressNotifierLoading
    extends StateNotifier<AsyncValue<List<Address>>> {
  MockAddressNotifierLoading() : super(const AsyncValue.loading());

  Future<void> loadAddresses() async {}

  Future<bool> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    return false;
  }

  Future<bool> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
  }) async {
    return false;
  }

  Future<bool> deleteAddress(String addressId) async {
    return false;
  }

  Future<bool> setDefaultAddress(String addressId) async {
    return false;
  }
}

/// Mock AddressNotifier with error state
class MockAddressNotifierError
    extends StateNotifier<AsyncValue<List<Address>>> {
  MockAddressNotifierError()
      : super(AsyncValue.error('Load failed', StackTrace.empty));

  Future<void> loadAddresses() async {}

  Future<bool> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    return false;
  }

  Future<bool> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
  }) async {
    return false;
  }

  Future<bool> deleteAddress(String addressId) async {
    return false;
  }

  Future<bool> setDefaultAddress(String addressId) async {
    return false;
  }
}
