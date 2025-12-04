import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/update_cart_item_quantity.dart';

import 'update_cart_item_quantity_test.mocks.dart';

@GenerateMocks([CartRepository])
void main() {
  late UpdateCartItemQuantityUseCase useCase;
  late MockCartRepository mockRepository;

  setUp(() {
    mockRepository = MockCartRepository();
    useCase = UpdateCartItemQuantityUseCase(mockRepository);
  });

  group('UpdateCartItemQuantityUseCase (T122)', () {
    const testCartItemId = 'cart-item-1';
    const testProductId = 'product-123';
    const testUserId = 'user-789';

    test('should update cart item quantity successfully', () async {
      // Arrange
      const newQuantity = 5;
      final updatedCartItem = CartItem(
        id: testCartItemId,
        userId: testUserId,
        productId: testProductId,
        variantId: null,
        quantity: newQuantity,
        addedAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.updateQuantity(
        cartItemId: testCartItemId,
        quantity: newQuantity,
      )).thenAnswer((_) async => updatedCartItem);

      // Act
      final result = await useCase.execute(
        cartItemId: testCartItemId,
        quantity: newQuantity,
      );

      // Assert
      expect(result.quantity, newQuantity);
      expect(result.id, testCartItemId);
      verify(mockRepository.updateQuantity(
        cartItemId: testCartItemId,
        quantity: newQuantity,
      )).called(1);
    });

    test('should throw exception when quantity is zero', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          cartItemId: testCartItemId,
          quantity: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(mockRepository.updateQuantity(
        cartItemId: anyNamed('cartItemId'),
        quantity: anyNamed('quantity'),
      ));
    });

    test('should throw exception when quantity is negative', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          cartItemId: testCartItemId,
          quantity: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should update to quantity 1 successfully', () async {
      // Arrange
      const newQuantity = 1;
      final updatedCartItem = CartItem(
        id: testCartItemId,
        userId: testUserId,
        productId: testProductId,
        variantId: null,
        quantity: newQuantity,
        addedAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.updateQuantity(
        cartItemId: testCartItemId,
        quantity: newQuantity,
      )).thenAnswer((_) async => updatedCartItem);

      // Act
      final result = await useCase.execute(
        cartItemId: testCartItemId,
        quantity: newQuantity,
      );

      // Assert
      expect(result.quantity, 1);
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.updateQuantity(
        cartItemId: testCartItemId,
        quantity: 3,
      )).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase.execute(
          cartItemId: testCartItemId,
          quantity: 3,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle cart item not found error', () async {
      // Arrange
      when(mockRepository.updateQuantity(
        cartItemId: testCartItemId,
        quantity: 3,
      )).thenThrow(Exception('Cart item not found'));

      // Act & Assert
      expect(
        () => useCase.execute(
          cartItemId: testCartItemId,
          quantity: 3,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
