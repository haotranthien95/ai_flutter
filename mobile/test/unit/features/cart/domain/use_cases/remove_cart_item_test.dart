import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/remove_cart_item.dart';

import 'remove_cart_item_test.mocks.dart';

@GenerateMocks([CartRepository])
void main() {
  late RemoveCartItemUseCase useCase;
  late MockCartRepository mockRepository;

  setUp(() {
    mockRepository = MockCartRepository();
    useCase = RemoveCartItemUseCase(mockRepository);
  });

  group('RemoveCartItemUseCase (T123)', () {
    const testCartItemId = 'cart-item-1';

    test('should remove cart item successfully', () async {
      // Arrange
      when(mockRepository.removeCartItem(testCartItemId))
          .thenAnswer((_) async => {});

      // Act
      await useCase.execute(testCartItemId);

      // Assert
      verify(mockRepository.removeCartItem(testCartItemId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.removeCartItem(testCartItemId))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase.execute(testCartItemId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle cart item not found error', () async {
      // Arrange
      when(mockRepository.removeCartItem(testCartItemId))
          .thenThrow(Exception('Cart item not found'));

      // Act & Assert
      expect(
        () => useCase.execute(testCartItemId),
        throwsA(isA<Exception>()),
      );
    });

    test('should complete successfully even if item does not exist', () async {
      // Arrange
      when(mockRepository.removeCartItem(testCartItemId))
          .thenAnswer((_) async => {});

      // Act & Assert - should not throw
      await useCase.execute(testCartItemId);
      verify(mockRepository.removeCartItem(testCartItemId)).called(1);
    });
  });
}
