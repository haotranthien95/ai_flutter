import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/features/cart/domain/models/cart.dart';
import 'package:ai_flutter/features/cart/presentation/cart_screen.dart';
import 'package:ai_flutter/features/cart/presentation/providers/cart_provider.dart';
import 'package:ai_flutter/features/cart/presentation/widgets/shop_cart_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartScreen Widget Tests (T128)', () {
    late List<CartItemWithProduct> testCartItems;
    late Cart testCart;

    setUp(() {
      final product1 = Product(
        id: 'product1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Test Product 1',
        description: 'Description 1',
        basePrice: 100000,
        currency: 'VND',
        totalStock: 50,
        images: ['image1.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.5,
        totalReviews: 10,
        soldCount: 5,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final product2 = Product(
        id: 'product2',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Test Product 2',
        description: 'Description 2',
        basePrice: 200000,
        currency: 'VND',
        totalStock: 30,
        images: ['image2.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.0,
        totalReviews: 8,
        soldCount: 3,
        isActive: true,
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      );

      final cartItem1 = CartItem(
        id: 'cart1',
        userId: 'user1',
        productId: 'product1',
        variantId: null,
        quantity: 2,
        addedAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final cartItem2 = CartItem(
        id: 'cart2',
        userId: 'user1',
        productId: 'product2',
        variantId: null,
        quantity: 1,
        addedAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      );

      testCartItems = [
        CartItemWithProduct(cartItem: cartItem1, product: product1),
        CartItemWithProduct(cartItem: cartItem2, product: product2),
      ];

      testCart = Cart(
        items: [cartItem1, cartItem2],
        products: [product1, product2],
        shopGroups: {
          'shop1': testCartItems,
        },
        itemCount: 3,
        totalAmount: 400000,
      );
    });

    testWidgets('should display empty cart state when cart is empty',
        (tester) async {
      // Arrange
      final emptyCart = Cart(
        items: const [],
        products: const [],
        shopGroups: const {},
        itemCount: 0,
        totalAmount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(emptyCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('should display loading indicator while loading cart',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => const AsyncValue.loading(),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display cart items grouped by shop', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(testCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ShopCartSection), findsOneWidget);
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
    });

    testWidgets('should display correct total amount in bottom bar',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(testCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check for bottom bar with total
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('₫400,000'), findsOneWidget);
    });

    testWidgets('should display checkout button in bottom bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(testCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });

    testWidgets('should navigate back when Start Shopping button is tapped',
        (tester) async {
      // Arrange
      final emptyCart = Cart(
        items: const [],
        products: const [],
        shopGroups: const {},
        itemCount: 0,
        totalAmount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(emptyCart),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Cart'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to CartScreen
      await tester.tap(find.text('Go to Cart'));
      await tester.pumpAndSettle();

      // Verify we're on CartScreen
      expect(find.text('Your cart is empty'), findsOneWidget);

      // Tap Start Shopping button
      await tester.tap(find.text('Start Shopping'));
      await tester.pumpAndSettle();

      // Assert - Should navigate back
      expect(find.text('Your cart is empty'), findsNothing);
      expect(find.text('Go to Cart'), findsOneWidget);
    });

    testWidgets('should display correct item count for multiple items',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(testCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Verify shop section exists with items
      expect(find.byType(ShopCartSection), findsOneWidget);
      // Verify both products are shown
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
    });

    testWidgets('should display Shopping Cart title in app bar',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(testCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should handle multiple shops in cart', (tester) async {
      // Arrange
      final product3 = Product(
        id: 'product3',
        shopId: 'shop2',
        categoryId: 'cat1',
        title: 'Test Product 3',
        description: 'Description 3',
        basePrice: 150000,
        currency: 'VND',
        totalStock: 20,
        images: ['image3.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.2,
        totalReviews: 5,
        soldCount: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 3),
        updatedAt: DateTime(2024, 1, 3),
      );

      final cartItem3 = CartItem(
        id: 'cart3',
        userId: 'user1',
        productId: 'product3',
        variantId: null,
        quantity: 1,
        addedAt: DateTime(2024, 1, 3),
        updatedAt: DateTime(2024, 1, 3),
      );

      final multiShopCart = Cart(
        items: [testCartItems[0].cartItem, cartItem3],
        products: [testCartItems[0].product, product3],
        shopGroups: {
          'shop1': [testCartItems[0]],
          'shop2': [
            CartItemWithProduct(cartItem: cartItem3, product: product3)
          ],
        },
        itemCount: 3,
        totalAmount: 350000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(
              (ref) => AsyncValue.data(multiShopCart),
            ),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should display 2 shop sections
      expect(find.byType(ShopCartSection), findsNWidgets(2));
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 3'), findsOneWidget);
    });
  });
}
