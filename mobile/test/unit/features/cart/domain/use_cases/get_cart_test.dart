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
          categoryId: 'cat-1',
          title: 'Product 1',
          description: 'Description 1',
          basePrice: 100000,
          currency: 'VND',
          totalStock: 10,
          images: <String>['image1.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.5,
          totalReviews: 10,
          soldCount: 5,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-2',
          shopId: testShopId1,
          categoryId: 'cat-1',
          title: 'Product 2',
          description: 'Description 2',
          basePrice: 50000,
          currency: 'VND',
          totalStock: 5,
          images: <String>['image2.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.0,
          totalReviews: 5,
          soldCount: 5,
          isActive: true,
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
          categoryId: 'cat-1',
          title: 'Product 1',
          description: 'Description 1',
          basePrice: 100000,
          currency: 'VND',
          totalStock: 10,
          images: <String>['image1.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.5,
          totalReviews: 10,
          soldCount: 5,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-2',
          shopId: testShopId1,
          categoryId: 'cat-1',
          title: 'Product 2',
          description: 'Description 2',
          basePrice: 50000,
          currency: 'VND',
          totalStock: 5,
          images: <String>['image2.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.0,
          totalReviews: 5,
          soldCount: 5,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 'product-3',
          shopId: testShopId2,
          categoryId: 'cat-2',
          title: 'Product 3',
          description: 'Description 3',
          basePrice: 75000,
          currency: 'VND',
          totalStock: 8,
          images: <String>['image3.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.8,
          totalReviews: 15,
          soldCount: 5,
          isActive: true,
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
          categoryId: 'cat-1',
          title: 'Product 1',
          description: 'Description 1',
          basePrice: 120000,
          currency: 'VND',
          totalStock: 10,
          images: <String>['image1.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.5,
          totalReviews: 10,
          soldCount: 5,
          isActive: true,
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
      expect(result.totalAmount, 240000); // 120000 * 2 (uses base price)
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
