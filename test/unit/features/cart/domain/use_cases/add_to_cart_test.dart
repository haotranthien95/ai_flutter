import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/add_to_cart.dart';

import 'add_to_cart_test.mocks.dart';

@GenerateMocks([CartRepository])
void main() {
  late AddToCartUseCase useCase;
  late MockCartRepository mockRepository;

  setUp(() {
    mockRepository = MockCartRepository();
    useCase = AddToCartUseCase(mockRepository);
  });

  group('AddToCartUseCase (T121)', () {
    const testProductId = 'product-123';
    const testVariantId = 'variant-456';
    const testUserId = 'user-789';
    const testQuantity = 2;

    test('should add product to empty cart successfully', () async {
      // Arrange
      final expectedCartItem = CartItem(
        id: 'cart-item-1',
        userId: testUserId,
        productId: testProductId,
        variantId: null,
        quantity: testQuantity,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => <CartItem>[]);
      when(mockRepository.addToCart(
        userId: testUserId,
        productId: testProductId,
        variantId: null,
        quantity: testQuantity,
      )).thenAnswer((_) async => expectedCartItem);

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        productId: testProductId,
        quantity: testQuantity,
      );

      // Assert
      expect(result, expectedCartItem);
      verify(mockRepository.getCart(testUserId)).called(1);
      verify(mockRepository.addToCart(
        userId: testUserId,
        productId: testProductId,
        variantId: null,
        quantity: testQuantity,
      )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should add product with variant to cart', () async {
      // Arrange
      final expectedCartItem = CartItem(
        id: 'cart-item-2',
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: testQuantity,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => <CartItem>[]);
      when(mockRepository.addToCart(
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: testQuantity,
      )).thenAnswer((_) async => expectedCartItem);

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: testQuantity,
      );

      // Assert
      expect(result.variantId, testVariantId);
      expect(result.quantity, testQuantity);
      verify(mockRepository.addToCart(
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: testQuantity,
      )).called(1);
    });

    test('should throw exception when quantity is zero', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          userId: testUserId,
          productId: testProductId,
          quantity: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(mockRepository.addToCart(
        userId: anyNamed('userId'),
        productId: anyNamed('productId'),
        variantId: anyNamed('variantId'),
        quantity: anyNamed('quantity'),
      ));
    });

    test('should throw exception when quantity is negative', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          userId: testUserId,
          productId: testProductId,
          quantity: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should update quantity when item already exists in cart', () async {
      // Arrange
      final existingCartItem = CartItem(
        id: 'cart-item-1',
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: 1,
        addedAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final updatedCartItem = existingCartItem.copyWith(
        quantity: existingCartItem.quantity + testQuantity,
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getCart(testUserId))
          .thenAnswer((_) async => <CartItem>[existingCartItem]);
      when(mockRepository.updateQuantity(
        cartItemId: existingCartItem.id,
        quantity: existingCartItem.quantity + testQuantity,
      )).thenAnswer((_) async => updatedCartItem);

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        productId: testProductId,
        variantId: testVariantId,
        quantity: testQuantity,
      );

      // Assert
      expect(result.quantity, 3); // 1 + 2
      verify(mockRepository.getCart(testUserId)).called(1);
      verify(mockRepository.updateQuantity(
        cartItemId: existingCartItem.id,
        quantity: 3,
      )).called(1);
      verifyNever(mockRepository.addToCart(
        userId: anyNamed('userId'),
        productId: anyNamed('productId'),
        variantId: anyNamed('variantId'),
        quantity: anyNamed('quantity'),
      ));
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.getCart(testUserId))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase.execute(
          userId: testUserId,
          productId: testProductId,
          quantity: testQuantity,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
