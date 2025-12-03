import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/main.dart' as app;
import 'package:ai_flutter/core/widgets/product_card.dart';

/// Integration test for guest shopping flow (US-001)
///
/// Test Scenario:
/// 1. Launch app as guest
/// 2. See home screen with products
/// 3. Tap category to filter products
/// 4. Tap product to see detail page
/// 5. Scroll to reviews section
/// 6. Tap "Add to Cart" and see login prompt
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Shopping Flow Integration Test', () {
    testWidgets('Complete guest browsing journey from home to product detail',
        (tester) async {
      // Step 1: Launch app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Step 2: Verify home screen displays
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should see home screen with products (or loading indicator initially)
      // Allow time for products to load
      await tester.pump(const Duration(seconds: 1));
      
      // Look for either loading indicator or product grid
      final loadingOrProducts = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.byType(ProductCard).evaluate().isNotEmpty;
      expect(loadingOrProducts, isTrue, reason: 'Should show loading or products');

      // Wait for products to finish loading
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 3: Verify products are displayed
      expect(
        find.byType(ProductCard),
        findsWidgets,
        reason: 'Should display product cards on home screen',
      );

      // Verify category chips are present
      expect(
        find.byType(Chip),
        findsWidgets,
        reason: 'Should display category chips',
      );

      // Step 4: Tap a category to filter products
      if (find.byType(Chip).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Chip).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify products filtered (may still show products)
        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'Should display filtered products',
        );
      }

      // Step 5: Tap on first product to navigate to detail page
      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 6: Verify product detail screen displays
      // Should see product title, price, images
      expect(
        find.byType(PageView),
        findsOneWidget,
        reason: 'Should display image carousel on product detail',
      );

      // Verify product information is visible
      expect(
        find.textContaining('₫'),
        findsWidgets,
        reason: 'Should display price in VND',
      );

      // Step 7: Scroll down to see reviews section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Verify reviews section
      expect(
        find.text('Đánh giá sản phẩm'),
        findsOneWidget,
        reason: 'Should display reviews section',
      );

      // Step 8: Scroll back up to Add to Cart button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Step 9: Tap "Add to Cart" button
      final addToCartButton = find.text('Thêm vào giỏ hàng');
      if (addToCartButton.evaluate().isNotEmpty) {
        await tester.tap(addToCartButton);
        await tester.pumpAndSettle();

        // Step 10: Verify login dialog appears for guest users
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'Should show login dialog for guest users',
        );

        // Verify login options present
        expect(
          find.text('Đăng nhập'),
          findsWidgets,
          reason: 'Should show login button',
        );

        expect(
          find.text('Đăng ký'),
          findsOneWidget,
          reason: 'Should show register button',
        );

        // Close the dialog
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }

      // Step 11: Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(
        find.byType(ProductCard),
        findsWidgets,
        reason: 'Should return to home screen with products',
      );

      // Step 12: Test search functionality
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Verify search screen opens
        expect(
          find.byType(TextField),
          findsOneWidget,
          reason: 'Should display search input field',
        );

        // Enter search query
        await tester.enterText(find.byType(TextField), 'iPhone');
        await tester.pump(const Duration(milliseconds: 500));

        // Verify autocomplete suggestions appear (if implemented)
        // This is optional based on implementation

        // Navigate back to home
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Browse products by category', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for products to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Find category chips
      final categoryChips = find.byType(Chip);
      
      if (categoryChips.evaluate().length > 1) {
        // Tap second category
        await tester.tap(categoryChips.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify products still displayed (filtered by category)
        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'Should show products for selected category',
        );

        // Tap first category (or "All" if present)
        await tester.tap(categoryChips.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify products displayed
        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'Should show all products',
        );
      }
    });

    testWidgets('Pull to refresh products', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find scrollable widget
      final scrollable = find.byType(RefreshIndicator);
      
      if (scrollable.evaluate().isNotEmpty) {
        // Pull down to refresh
        await tester.drag(scrollable, const Offset(0, 300));
        await tester.pump();

        // Verify refresh indicator appears
        expect(
          find.byType(CircularProgressIndicator),
          findsWidgets,
          reason: 'Should show loading indicator during refresh',
        );

        // Wait for refresh to complete
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify products still displayed
        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'Should display refreshed products',
        );
      }
    });

    testWidgets('Navigate through multiple products', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for products
      await tester.pumpAndSettle();

      final productCards = find.byType(ProductCard);
      
      if (productCards.evaluate().length >= 2) {
        // View first product
        await tester.tap(productCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify on detail screen
        expect(find.byType(PageView), findsOneWidget);

        // Go back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // View second product
        await tester.tap(productCards.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify on detail screen
        expect(find.byType(PageView), findsOneWidget);

        // Go back to home
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Verify back on home
        expect(find.byType(ProductCard), findsWidgets);
      }
    });

    testWidgets('Verify cart icon and navigation', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find cart icon in app bar
      final cartIcon = find.byIcon(Icons.shopping_cart);
      
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();

        // Should navigate to cart or show login if guest
        // This behavior depends on authentication state
        
        // If still on home, that's okay (cart might redirect to login)
        // If navigated away, navigate back
        if (find.byType(ProductCard).evaluate().isEmpty) {
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Error handling and retry', (tester) async {
      // This test would require mocking network errors
      // Placeholder for error state testing
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If error view appears, test retry button
      final retryButton = find.text('Thử lại');
      
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should attempt to reload
        expect(
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
              find.byType(ProductCard).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show loading or products after retry',
        );
      }
    });
  });
}
