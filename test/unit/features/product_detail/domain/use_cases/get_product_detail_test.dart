import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/features/product_detail/domain/use_cases/get_product_detail.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/product_variant.dart';

@GenerateMocks([ProductRepository])
import 'get_product_detail_test.mocks.dart';

void main() {
  late GetProductDetailUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductDetailUseCase(mockRepository);
  });

  group('GetProductDetailUseCase', () {
    final testProduct = Product(
      id: '1',
      shopId: 'shop1',
      categoryId: 'cat1',
      title: 'Test Product',
      description: 'Detailed description',
      basePrice: 100000,
      currency: 'VND',
      totalStock: 50,
      images: ['image1.jpg', 'image2.jpg', 'image3.jpg'],
      condition: ProductCondition.newProduct,
      averageRating: 4.5,
      totalReviews: 25,
      soldCount: 10,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testVariants = [
      ProductVariant(
        id: 'var1',
        productId: '1',
        name: 'Red - Large',
        attributes: {'color': 'Red', 'size': 'L'},
        sku: 'PROD-RED-L',
        price: 100000,
        stock: 20,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      ProductVariant(
        id: 'var2',
        productId: '1',
        name: 'Blue - Medium',
        attributes: {'color': 'Blue', 'size': 'M'},
        sku: 'PROD-BLUE-M',
        price: 100000,
        stock: 20,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
    test('should fetch product detail successfully', () async {
      // Arrange
      const productId = '1';
      when(mockRepository.getProductDetail(productId))
          .thenAnswer((_) async => testProduct);

      // Act
      final result = await useCase.execute(productId);

      // Assert
      expect(result, equals(testProduct));
      verify(mockRepository.getProductDetail(productId)).called(1);
    });

    test('should throw exception when product not found (404)', () async {
      // Arrange
      const productId = 'nonexistent';
      when(mockRepository.getProductDetail(productId))
          .thenThrow(Exception('Product not found'));

      // Act & Assert
      expect(
        () => useCase.execute(productId),
        throwsException,
      );
    });

    test('should throw exception when productId is empty', () async {
      // Act & Assert
      expect(
        () => useCase.execute(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should fetch product with variants', () async {
      // Arrange
      const productId = '1';
      when(mockRepository.getProductDetail(productId))
          .thenAnswer((_) async => testProduct);
      when(mockRepository.getProductVariants(productId))
          .thenAnswer((_) async => testVariants);

      // Act
      final result = await useCase.execute(productId);

      // Assert
      expect(result, equals(testProduct));
      verify(mockRepository.getProductDetail(productId)).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      const productId = '1';
      when(mockRepository.getProductDetail(productId))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.execute(productId),
        throwsException,
      );
    });

    test('should handle inactive product', () async {
      // Arrange
      const productId = '1';
      final inactiveProduct = Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Inactive Product',
        description: 'Description',
        basePrice: 100000,
        currency: 'VND',
        totalStock: 0,
        images: ['image.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 0,
        totalReviews: 0,
        soldCount: 0,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockRepository.getProductDetail(productId))
          .thenAnswer((_) async => inactiveProduct);

      // Act
      final result = await useCase.execute(productId);

      // Assert
      expect(result.isActive, isFalse);
    });
  });
}
