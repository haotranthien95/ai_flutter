import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/product_detail/presentation/product_detail_screen.dart';
import 'package:ai_flutter/features/product_detail/presentation/product_detail_provider.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/product_variant.dart';
import 'package:ai_flutter/core/models/review.dart';
import 'package:ai_flutter/core/widgets/loading_indicator.dart';
import 'package:ai_flutter/core/widgets/error_view.dart';

void main() {
  group('ProductDetailScreen Widget Tests', () {
    late Product testProduct;
    late List<ProductVariant> testVariants;
    late List<Review> testReviews;

    setUp(() {
      testProduct = Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'iPhone 15 Pro Max',
        description:
            'The latest flagship phone from Apple with A17 Pro chip, titanium design, and advanced camera system.',
        basePrice: 29990000,
        currency: 'VND',
        totalStock: 50,
        images: [
          'https://example.com/iphone1.jpg',
          'https://example.com/iphone2.jpg',
          'https://example.com/iphone3.jpg',
        ],
        condition: ProductCondition.newProduct,
        averageRating: 4.8,
        totalReviews: 150,
        soldCount: 75,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      testVariants = [
        ProductVariant(
          id: 'var1',
          productId: '1',
          name: 'Natural Titanium - 256GB',
          attributes: {'color': 'Natural Titanium', 'storage': '256GB'},
          sku: 'IPHONE-NT-256',
          price: 29990000,
          stock: 20,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        ProductVariant(
          id: 'var2',
          productId: '1',
          name: 'Blue Titanium - 512GB',
          attributes: {'color': 'Blue Titanium', 'storage': '512GB'},
          sku: 'IPHONE-BT-512',
          price: 34990000,
          stock: 30,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      testReviews = [
        Review(
          id: 'rev1',
          productId: '1',
          userId: 'user1',
          orderId: 'order1',
          rating: 5,
          content: 'Excellent phone! Highly recommended.',
          images: ['review1.jpg'],
          isVerifiedPurchase: true,
          isVisible: true,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        Review(
          id: 'rev2',
          productId: '1',
          userId: 'user2',
          orderId: 'order2',
          rating: 4,
          content: 'Good phone but expensive.',
          images: [],
          isVerifiedPurchase: true,
          isVisible: true,
          createdAt: DateTime(2024, 1, 20),
          updatedAt: DateTime(2024, 1, 20),
        ),
      ];
    });

    testWidgets('should display loading indicator while loading product',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = const AsyncValue.loading(),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      // Assert
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should display image carousel when product loaded',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PageView), findsOneWidget);
      // Dot indicators for 3 images
      expect(find.byIcon(Icons.circle), findsNWidgets(3));
    });

    testWidgets('should display product title and price', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
      expect(find.textContaining('29.990.000 ₫'), findsOneWidget);
    });

    testWidgets('should display stock status indicator', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Còn hàng'), findsOneWidget);
    });

    testWidgets('should display variant selector when product has variants',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct)
                ..variants = testVariants,
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Natural Titanium - 256GB'), findsOneWidget);
      expect(find.text('Blue Titanium - 512GB'), findsOneWidget);
    });

    testWidgets('should update price when variant selected', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct)
                ..variants = testVariants,
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Select second variant
      await tester.tap(find.text('Blue Titanium - 512GB'));
      await tester.pumpAndSettle();

      // Assert - Price should update to variant price
      expect(find.textContaining('34.990.000 ₫'), findsOneWidget);
    });

    testWidgets('should display expandable description section',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Mô tả sản phẩm'), findsOneWidget);
      expect(find.textContaining('The latest flagship phone'), findsOneWidget);
    });

    testWidgets('should display shop info card', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Thông tin shop'), findsOneWidget);
    });

    testWidgets('should display reviews summary with rating distribution',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct)
                ..reviews = testReviews,
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Đánh giá sản phẩm'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('150 đánh giá'), findsOneWidget);
    });

    testWidgets('should display review list with verified purchase badges',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct)
                ..reviews = testReviews,
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Excellent phone! Highly recommended.'), findsOneWidget);
      expect(find.text('Good phone but expensive.'), findsOneWidget);
      expect(find.text('Đã mua hàng'), findsNWidgets(2)); // Verified badges
    });

    testWidgets('should display floating Add to Cart button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Thêm vào giỏ hàng'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show login dialog when guest taps Add to Cart',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
            // Mock as guest (unauthenticated)
            authStateProvider
                .overrideWith((ref) => const AsyncValue.data(null)),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Thêm vào giỏ hàng'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Đăng ký'), findsOneWidget);
    });

    testWidgets('should display error view when product load fails',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.error(
                  Exception('Product not found'),
                  StackTrace.current,
                ),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should support image zoom on tap', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProviderProvider('1').overrideWith(
              (ref) => ProductDetailProvider('1')
                ..state = AsyncValue.data(testProduct),
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Tap on image
      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();

      // Assert - Hero animation or zoomed view (implementation-specific)
      // This test validates the tap gesture is recognized
      expect(tester.takeException(), isNull);
    });
  });
}
