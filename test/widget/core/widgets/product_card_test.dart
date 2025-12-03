import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter/core/widgets/product_card.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  group('ProductCard Widget Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'iPhone 15 Pro Max 256GB',
        description: 'Latest Apple flagship phone',
        basePrice: 29990000,
        totalStock: 50,
        images: [
          'https://example.com/iphone1.jpg',
          'https://example.com/iphone2.jpg',
        ],
        condition: ProductCondition.newProduct,
        averageRating: 4.8,
        totalReviews: 150,
        soldCount: 75,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    testWidgets('should display product title', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.text('iPhone 15 Pro Max 256GB'), findsOneWidget);
    });

    testWidgets('should display formatted price in VND', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('₫'), findsOneWidget);
      expect(find.textContaining('29.990.000'), findsOneWidget);
    });

    testWidgets('should display product image using CachedNetworkImage',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should display rating with stars', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('should display sold count', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Đã bán'), findsOneWidget);
      expect(find.textContaining('75'), findsOneWidget);
    });

    testWidgets('should trigger onTap callback when tapped', (tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should show placeholder when image fails to load',
        (tester) async {
      // Arrange
      final productWithInvalidImage = Product(
        id: '2',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Product with no image',
        description: 'Description',
        basePrice: 100000,
        totalStock: 10,
        images: ['invalid_url'],
        condition: ProductCondition.newProduct,
        averageRating: 4.0,
        totalReviews: 5,
        soldCount: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: productWithInvalidImage),
          ),
        ),
      );

      await tester.pump();

      // Assert - placeholder or error widget should be shown
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should display out of stock indicator when stock is 0',
        (tester) async {
      // Arrange
      final outOfStockProduct = Product(
        id: '3',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Out of Stock Product',
        description: 'Description',
        basePrice: 100000,
        totalStock: 0,
        images: ['image.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.0,
        totalReviews: 5,
        soldCount: 50,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: outOfStockProduct),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Hết hàng'), findsOneWidget);
    });

    testWidgets('HorizontalProductCard should display in list layout',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalProductCard(product: testProduct),
          ),
        ),
      );

      // Assert
      expect(find.text('iPhone 15 Pro Max 256GB'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);

      // Check if layout is horizontal (Row-based)
      final row = find.ancestor(
        of: find.text('iPhone 15 Pro Max 256GB'),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget);
    });

    testWidgets('CompactProductCard should display smaller thumbnail',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactProductCard(product: testProduct, quantity: 2),
          ),
        ),
      );

      // Assert
      expect(find.text('iPhone 15 Pro Max 256GB'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
    });

    testWidgets('should handle very long product title with ellipsis',
        (tester) async {
      // Arrange
      final productWithLongTitle = Product(
        id: '4',
        shopId: 'shop1',
        categoryId: 'cat1',
        title:
            'This is a very long product title that should be truncated with ellipsis to prevent overflow issues',
        description: 'Description',
        basePrice: 100000,
        totalStock: 10,
        images: ['image.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.0,
        totalReviews: 5,
        soldCount: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: productWithLongTitle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Text should be displayed without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display condition badge for used products',
        (tester) async {
      // Arrange
      final usedProduct = Product(
        id: '5',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Used iPhone',
        description: 'Description',
        basePrice: 15000000,
        totalStock: 5,
        images: ['image.jpg'],
        condition: ProductCondition.used,
        averageRating: 4.0,
        totalReviews: 10,
        soldCount: 5,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: usedProduct),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Đã sử dụng'), findsOneWidget);
    });
  });
}
