import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/features/home/domain/use_cases/get_products.dart';
import 'package:ai_flutter/core/models/product.dart';

@GenerateMocks([ProductRepository])
import 'get_products_test.mocks.dart';

void main() {
  late GetProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductsUseCase(mockRepository);
  });

  group('GetProductsUseCase', () {
    final testProducts = [
      Product(
        id: '1',
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should fetch products successfully from repository', () async {
      // Arrange
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(testProducts));
      verify(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should apply default limit of 20 when not specified', () async {
      // Arrange
      when(mockRepository.getProducts(
        limit: 20,
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      await useCase.execute();

      // Assert
      verify(mockRepository.getProducts(
        limit: 20,
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should filter by category when categoryId provided', () async {
      // Arrange
      const categoryId = 'cat1';
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: categoryId,
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      await useCase.execute(categoryId: categoryId);

      // Assert
      verify(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: categoryId,
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsException,
      );
    });

    test('should apply sorting parameter', () async {
      // Arrange
      const sortBy = 'price_low_high';
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: sortBy,
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      await useCase.execute(sortBy: sortBy);

      // Assert
      verify(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: sortBy,
      )).called(1);
    });

    test('should apply filters parameter', () async {
      // Arrange
      final filters = <String, dynamic>{
        'minPrice': 100000,
        'maxPrice': 500000,
        'condition': 'new',
      };
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: filters,
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      await useCase.execute(filters: filters);

      // Assert
      verify(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: filters,
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should support pagination with cursor', () async {
      // Arrange
      const cursor = 'page2_cursor';
      when(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: cursor,
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => List<Product>.from(testProducts));

      // Act
      await useCase.execute(cursor: cursor);

      // Assert
      verify(mockRepository.getProducts(
        limit: anyNamed('limit'),
        cursor: cursor,
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });
  });
}
