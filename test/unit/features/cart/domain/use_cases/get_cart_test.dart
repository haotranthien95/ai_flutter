import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/get_cart.dart';
import 'package:ai_flutter/features/cart/domain/models/cart.dart';

import 'get_cart_test.mocks.dart';

@GenerateMocks([CartRepository])
void main() {
  late GetCartUseCase useCase;
  late MockCartRepository mockRepository;

  setUp(() {
    mockRepository = MockCartRepository();
    useCase = GetCartUseCase(mockRepository);
  });

  group('GetCartUseCase (T124)', () {
    const testUserId = 'user-789';
    const testShopId1 = 'shop-1';
    const testShopId2 = 'shop-2';

    test('should return empty cart when user has no cart items', () async {
      // Arrange
      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => <CartItem>[]);

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.items, isEmpty);
      expect(result.itemCount, 0);
      expect(result.totalAmount, 0);
      verify(mockRepository.getCart(testUserId)).called(1);
    });

    test('should get cart with items from single shop', () async {
      // Arrange
      final cartItems = <CartItem>[
        CartItem(
          id: 'cart-item-1',
          userId: testUserId,
          productId: 'product-1',
          variantId: null,
          quantity: 2,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CartItem(
          id: 'cart-item-2',
          userId: testUserId,
          productId: 'product-2',
          variantId: null,
          quantity: 1,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final products = <Product>[
        Product(
          id: 'product-1',
          shopId: testShopId1,
          title: 'Product 1',
          description: 'Description 1',
          categoryId: 'cat-1',
          categoryName: 'Category',
          basePrice: 100000,
          currentPrice: 100000,
          discountPercentage: null,
          stockQuantity: 10,
          sku: 'SKU1',
          weight: null,
          dimensions: null,
          images: <String>['image1.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.5,
          totalReviews: 10,
          totalSold: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-2',
          shopId: testShopId1,
          title: 'Product 2',
          description: 'Description 2',
          categoryId: 'cat-1',
          categoryName: 'Category',
          basePrice: 50000,
          currentPrice: 50000,
          discountPercentage: null,
          stockQuantity: 5,
          sku: 'SKU2',
          weight: null,
          dimensions: null,
          images: <String>['image2.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.0,
          totalReviews: 5,
          totalSold: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => cartItems);
      when(mockRepository.getProductsForCart(any))
          .thenAnswer((_) async => products);

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.items.length, 2);
      expect(result.itemCount, 3); // 2 + 1
      expect(result.totalAmount, 250000); // (100000 * 2) + (50000 * 1)
      expect(result.shopGroups.length, 1);
      expect(result.shopGroups[testShopId1]?.length, 2);
    });

    test('should group cart items by shop', () async {
      // Arrange
      final cartItems = <CartItem>[
        CartItem(
          id: 'cart-item-1',
          userId: testUserId,
          productId: 'product-1',
          variantId: null,
          quantity: 2,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CartItem(
          id: 'cart-item-2',
          userId: testUserId,
          productId: 'product-2',
          variantId: null,
          quantity: 1,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CartItem(
          id: 'cart-item-3',
          userId: testUserId,
          productId: 'product-3',
          variantId: null,
          quantity: 3,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final products = <Product>[
        Product(
          id: 'product-1',
          shopId: testShopId1,
          title: 'Product 1',
          description: 'Description 1',
          categoryId: 'cat-1',
          categoryName: 'Category',
          basePrice: 100000,
          currentPrice: 100000,
          discountPercentage: null,
          stockQuantity: 10,
          sku: 'SKU1',
          weight: null,
          dimensions: null,
          images: <String>['image1.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.5,
          totalReviews: 10,
          totalSold: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-2',
          shopId: testShopId1,
          title: 'Product 2',
          description: 'Description 2',
          categoryId: 'cat-1',
          categoryName: 'Category',
          basePrice: 50000,
          currentPrice: 50000,
          discountPercentage: null,
          stockQuantity: 5,
          sku: 'SKU2',
          weight: null,
          dimensions: null,
          images: <String>['image2.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.0,
          totalReviews: 5,
          totalSold: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-3',
          shopId: testShopId2,
          title: 'Product 3',
          description: 'Description 3',
          categoryId: 'cat-2',
          categoryName: 'Category 2',
          basePrice: 75000,
          currentPrice: 75000,
          discountPercentage: null,
          stockQuantity: 8,
          sku: 'SKU3',
          weight: null,
          dimensions: null,
          images: <String>['image3.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.8,
          totalReviews: 15,
          totalSold: 40,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => cartItems);
      when(mockRepository.getProductsForCart(any))
          .thenAnswer((_) async => products);

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.shopGroups.length, 2);
      expect(result.shopGroups[testShopId1]?.length, 2);
      expect(result.shopGroups[testShopId2]?.length, 1);
      expect(result.totalAmount, 475000); // (100000*2) + (50000*1) + (75000*3)
    });

    test('should calculate subtotal per shop correctly', () async {
      // Arrange
      final cartItems = <CartItem>[
        CartItem(
          id: 'cart-item-1',
          userId: testUserId,
          productId: 'product-1',
          variantId: null,
          quantity: 2,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final products = <Product>[
        Product(
          id: 'product-1',
          shopId: testShopId1,
          title: 'Product 1',
          description: 'Description 1',
          categoryId: 'cat-1',
          categoryName: 'Category',
          basePrice: 150000,
          currentPrice: 120000, // Discounted
          discountPercentage: 20,
          stockQuantity: 10,
          sku: 'SKU1',
          weight: null,
          dimensions: null,
          images: <String>['image1.jpg'],
          isActive: true,
          hasVariants: false,
          averageRating: 4.5,
          totalReviews: 10,
          totalSold: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => cartItems);
      when(mockRepository.getProductsForCart(any))
          .thenAnswer((_) async => products);

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.totalAmount, 240000); // 120000 * 2 (uses current price)
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.getCart(testUserId))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase.execute(testUserId),
        throwsA(isA<Exception>()),
      );
    });
  });
}
