import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/features/home/domain/use_cases/search_products.dart';
import 'package:ai_flutter/core/models/product.dart';

@GenerateMocks([ProductRepository])
import 'search_products_test.mocks.dart';

void main() {
  late SearchProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = SearchProductsUseCase(mockRepository);
  });

  group('SearchProductsUseCase', () {
    final testProducts = [
      Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'iPhone 15 Pro Max',
        description: 'Latest Apple phone',
        basePrice: 25000000,
        totalStock: 50,
        images: ['iphone.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.8,
        totalReviews: 100,
        soldCount: 50,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should search products with keyword', () async {
      // Arrange
      const keyword = 'iPhone';
      when(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => testProducts);

      // Act
      final result = await useCase.execute(query: keyword);

      // Assert
      expect(result, equals(testProducts));
      verify(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should return empty list when no results found', () async {
      // Arrange
      const keyword = 'nonexistent product';
      when(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(query: keyword);

      // Assert
      expect(result, isEmpty);
    });

    test('should apply pagination with limit and cursor', () async {
      // Arrange
      const keyword = 'phone';
      const limit = 10;
      const cursor = 'page2';
      when(mockRepository.searchProducts(
        query: keyword,
        limit: limit,
        cursor: cursor,
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => testProducts);

      // Act
      await useCase.execute(query: keyword, limit: limit, cursor: cursor);

      // Assert
      verify(mockRepository.searchProducts(
        query: keyword,
        limit: limit,
        cursor: cursor,
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should throw exception when query is empty', () async {
      // Act & Assert
      expect(
        () => useCase.execute(query: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      const keyword = 'phone';
      when(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.execute(query: keyword),
        throwsException,
      );
    });

    test('should apply filters to search', () async {
      // Arrange
      const keyword = 'phone';
      final filters = <String, dynamic>{
        'minPrice': 5000000,
        'maxPrice': 30000000,
        'rating': 4.0,
      };
      when(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: filters,
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => testProducts);

      // Act
      await useCase.execute(query: keyword, filters: filters);

      // Assert
      verify(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: filters,
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should apply sorting to search results', () async {
      // Arrange
      const keyword = 'phone';
      const sortBy = 'price_high_low';
      when(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: sortBy,
      )).thenAnswer((_) async => testProducts);

      // Act
      await useCase.execute(query: keyword, sortBy: sortBy);

      // Assert
      verify(mockRepository.searchProducts(
        query: keyword,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: sortBy,
      )).called(1);
    });
  });
}
