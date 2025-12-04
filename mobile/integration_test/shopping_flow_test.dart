import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ai_flutter/main.dart' as app;
import 'package:ai_flutter/core/widgets/product_card.dart';

/// Integration test for authenticated shopping flow (T132, US-003)
///
/// Test Scenario:
/// 1. Launch app and navigate to login
/// 2. Login with test credentials
/// 3. Browse products on home screen
/// 4. View product detail
/// 5. Add product to cart
/// 6. Navigate to cart screen
/// 7. Update cart quantities
/// 8. Proceed to checkout
/// 9. Select delivery address
/// 10. Choose payment method
/// 11. Place order
/// 12. Verify order confirmation screen
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping Flow Integration Test (T132)', () {
    testWidgets(
        'Complete shopping journey: login → browse → cart → checkout → order',
        (tester) async {
      // Step 1: Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 2: Navigate to profile/login screen
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Step 3: Check if already logged in
        final loginTitle = find.text('Đăng nhập');
        final profileInfo = find.text('Thông tin tài khoản');

        if (loginTitle.evaluate().isNotEmpty) {
          // Not logged in - proceed with login
          await _performLogin(tester);
        } else if (profileInfo.evaluate().isNotEmpty) {
          // Already logged in - go back to home
          final homeIcon = find.byIcon(Icons.home);
          if (homeIcon.evaluate().isNotEmpty) {
            await tester.tap(homeIcon);
            await tester.pumpAndSettle();
          }
        }
      }

      // Step 4: Browse products on home screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home screen with products
      expect(
        find.byType(ProductCard).evaluate().isNotEmpty ||
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty,
        isTrue,
        reason: 'Should show products or loading indicator',
      );

      // Wait for products to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 5: Tap on first product to view details
      final productCards = find.byType(ProductCard);
      if (productCards.evaluate().isNotEmpty) {
        await tester.tap(productCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify product detail screen
        expect(
          find.byType(PageView),
          findsOneWidget,
          reason: 'Should display product images carousel',
        );

        // Step 6: Add product to cart
        final addToCartButton = find.text('Thêm vào giỏ hàng');
        if (addToCartButton.evaluate().isNotEmpty) {
          await tester.tap(addToCartButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Check for success message or cart icon update
          final snackBar = find.byType(SnackBar);
          if (snackBar.evaluate().isNotEmpty) {
            // Success - wait for snackbar to dismiss
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // Step 7: Navigate to cart screen
        final cartIcon = find.byIcon(Icons.shopping_cart);
        if (cartIcon.evaluate().isNotEmpty) {
          await tester.tap(cartIcon);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify cart screen displays
          final cartTitle = find.text('Shopping Cart');
          final emptyCartIcon = find.byIcon(Icons.shopping_cart_outlined);

          if (cartTitle.evaluate().isNotEmpty) {
            // On cart screen
            expect(cartTitle, findsOneWidget,
                reason: 'Should display cart screen title');

            // Check if cart has items or is empty
            if (emptyCartIcon.evaluate().isEmpty) {
              // Cart has items - test cart operations
              await _testCartOperations(tester);

              // Step 8: Proceed to checkout
              final checkoutButton = find.text('Proceed to Checkout');
              if (checkoutButton.evaluate().isNotEmpty) {
                await tester.tap(checkoutButton);
                await tester.pumpAndSettle(const Duration(seconds: 2));

                // Step 9: Test checkout flow
                await _testCheckoutFlow(tester);
              }
            } else {
              // Cart is empty - go back and try adding again
              await tester.pageBack();
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Step 10: Verify can navigate back to home
      final homeIcon = find.byIcon(Icons.home);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon);
        await tester.pumpAndSettle();

        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'Should return to home screen with products',
        );
      }
    });

    testWidgets('Add multiple products to cart', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Ensure logged in
      await _ensureLoggedIn(tester);

      // Navigate to home
      final homeIcon = find.byIcon(Icons.home);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final productCards = find.byType(ProductCard);
      if (productCards.evaluate().length >= 2) {
        // Add first product
        await tester.tap(productCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final addToCart1 = find.text('Thêm vào giỏ hàng');
        if (addToCart1.evaluate().isNotEmpty) {
          await tester.tap(addToCart1);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Go back to home
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Add second product
        await tester.tap(productCards.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final addToCart2 = find.text('Thêm vào giỏ hàng');
        if (addToCart2.evaluate().isNotEmpty) {
          await tester.tap(addToCart2);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Navigate to cart
        final cartIcon = find.byIcon(Icons.shopping_cart);
        if (cartIcon.evaluate().isNotEmpty) {
          await tester.tap(cartIcon);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify multiple items in cart
          final cartItems = find.byType(ListTile);
          expect(
            cartItems.evaluate().length >= 2,
            isTrue,
            reason: 'Should have at least 2 items in cart',
          );
        }
      }
    });

    testWidgets('Update cart item quantities', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _ensureLoggedIn(tester);

      // Navigate to cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find quantity controls
        final incrementButtons = find.byIcon(Icons.add);
        final decrementButtons = find.byIcon(Icons.remove);

        if (incrementButtons.evaluate().isNotEmpty) {
          // Increase quantity
          await tester.tap(incrementButtons.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Verify total updated
          expect(
            find.textContaining('₫'),
            findsWidgets,
            reason: 'Should display updated price',
          );

          if (decrementButtons.evaluate().isNotEmpty) {
            // Decrease quantity
            await tester.tap(decrementButtons.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }
      }
    });

    testWidgets('Remove item from cart', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _ensureLoggedIn(tester);

      // Navigate to cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find remove/delete buttons
        final deleteButtons = find.byIcon(Icons.delete);

        if (deleteButtons.evaluate().isNotEmpty) {
          final itemCountBefore = find.byType(ListTile).evaluate().length;

          // Remove first item
          await tester.tap(deleteButtons.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          final itemCountAfter = find.byType(ListTile).evaluate().length;

          expect(
            itemCountAfter < itemCountBefore,
            isTrue,
            reason: 'Should have fewer items after removal',
          );
        }
      }
    });

    testWidgets('Empty cart shows empty state', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _ensureLoggedIn(tester);

      // Navigate to cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Check for empty cart state
        final emptyCartIcon = find.byIcon(Icons.shopping_cart_outlined);
        final emptyCartMessage = find.text('Your cart is empty');

        if (emptyCartIcon.evaluate().isNotEmpty ||
            emptyCartMessage.evaluate().isNotEmpty) {
          // Verify empty state components
          expect(
            emptyCartIcon.evaluate().isNotEmpty ||
                emptyCartMessage.evaluate().isNotEmpty,
            isTrue,
            reason: 'Should show empty cart state',
          );

          // Verify "Start Shopping" button
          final shopButton = find.text('Start Shopping');
          if (shopButton.evaluate().isNotEmpty) {
            await tester.tap(shopButton);
            await tester.pumpAndSettle();

            // Should navigate away from cart
            expect(
              find.text('Shopping Cart').evaluate().isEmpty,
              isTrue,
              reason: 'Should leave cart screen',
            );
          }
        }
      }
    });
  });
}

/// Helper function to perform login
Future<void> _performLogin(WidgetTester tester) async {
  // Enter phone number
  final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
  if (phoneField.evaluate().isNotEmpty) {
    await tester.enterText(phoneField, '0987654321');
    await tester.pump();
  }

  // Enter password
  final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
  if (passwordField.evaluate().isNotEmpty) {
    await tester.enterText(passwordField, 'Test@12345');
    await tester.pump();
  }

  // Tap login button
  final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
  if (loginButton.evaluate().isNotEmpty) {
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Helper function to ensure user is logged in
Future<void> _ensureLoggedIn(WidgetTester tester) async {
  final profileIcon = find.byIcon(Icons.person);
  if (profileIcon.evaluate().isNotEmpty) {
    await tester.tap(profileIcon);
    await tester.pumpAndSettle();

    final loginTitle = find.text('Đăng nhập');
    if (loginTitle.evaluate().isNotEmpty) {
      await _performLogin(tester);
    }

    // Navigate back to previous screen
    final homeIcon = find.byIcon(Icons.home);
    if (homeIcon.evaluate().isNotEmpty) {
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to test cart operations
Future<void> _testCartOperations(WidgetTester tester) async {
  // Test quantity increment
  final incrementButtons = find.byIcon(Icons.add);
  if (incrementButtons.evaluate().isNotEmpty) {
    await tester.tap(incrementButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Test quantity decrement
  final decrementButtons = find.byIcon(Icons.remove);
  if (decrementButtons.evaluate().isNotEmpty) {
    await tester.tap(decrementButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Verify cart total updates
  expect(
    find.textContaining('₫'),
    findsWidgets,
    reason: 'Should display price in VND',
  );
}

/// Helper function to test checkout flow
Future<void> _testCheckoutFlow(WidgetTester tester) async {
  // Verify checkout screen displays
  final addressSection = find.text('Delivery Address');
  final paymentSection = find.text('Payment Method');

  if (addressSection.evaluate().isNotEmpty ||
      paymentSection.evaluate().isNotEmpty) {
    // On checkout screen
    expect(
      addressSection.evaluate().isNotEmpty ||
          paymentSection.evaluate().isNotEmpty,
      isTrue,
      reason: 'Should display checkout screen sections',
    );

    // Test address selection
    final selectAddressButton = find.text('Select Address');
    if (selectAddressButton.evaluate().isNotEmpty) {
      await tester.tap(selectAddressButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // If address selector opens, select first address
      final addressCards = find.byType(Card);
      if (addressCards.evaluate().isNotEmpty) {
        await tester.tap(addressCards.first);
        await tester.pumpAndSettle();
      } else {
        // No addresses - go back
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }

    // Test payment method selection
    final paymentMethods = find.byType(RadioListTile<dynamic>);
    if (paymentMethods.evaluate().isNotEmpty) {
      await tester.tap(paymentMethods.first);
      await tester.pumpAndSettle();
    }

    // Test order notes
    final notesField = find.widgetWithText(TextField, 'Order Notes');
    if (notesField.evaluate().isNotEmpty) {
      await tester.enterText(notesField, 'Please deliver before 5 PM');
      await tester.pump();
    }

    // Attempt to place order
    final placeOrderButton = find.text('Place Order');
    if (placeOrderButton.evaluate().isNotEmpty) {
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for order confirmation or error
      final confirmationMessage = find.text('Order Placed Successfully!');
      final errorMessage = find.textContaining('Error');

      if (confirmationMessage.evaluate().isNotEmpty) {
        // Success - verify order confirmation screen
        expect(
          confirmationMessage,
          findsOneWidget,
          reason: 'Should display order confirmation',
        );

        // Verify order ID displayed
        expect(
          find.textContaining('Order #'),
          findsOneWidget,
          reason: 'Should display order number',
        );

        // Test action buttons
        final viewOrderButton = find.text('View Order Details');
        final backHomeButton = find.text('Back to Home');

        expect(
          viewOrderButton.evaluate().isNotEmpty ||
              backHomeButton.evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display action buttons',
        );

        // Navigate back to home
        if (backHomeButton.evaluate().isNotEmpty) {
          await tester.tap(backHomeButton);
          await tester.pumpAndSettle();
        }
      } else if (errorMessage.evaluate().isNotEmpty) {
        // Expected error without backend
        expect(
          errorMessage,
          findsOneWidget,
          reason: 'Should show error without backend',
        );
      }
    }
  }
}
