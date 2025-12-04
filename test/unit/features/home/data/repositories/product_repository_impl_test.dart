import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/home/data/repositories/product_repository_impl.dart';
import 'package:ai_flutter/features/home/data/data_sources/product_remote_data_source.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/category.dart';

@GenerateMocks([ProductRemoteDataSource])
import 'product_repository_impl_test.mocks.dart';

void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProductRemoteDataSource();
    repository = ProductRepositoryImpl(mockDataSource);
  });

  group('ProductRepositoryImpl - getProducts', () {
    final testProducts = [
      Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'Test Product',
        description: 'Description',
        basePrice: 100000,
        currency: 'VND',
        totalStock: 50,
        images: ['image.jpg'],
        condition: ProductCondition.newProduct,
        averageRating: 4.5,
        totalReviews: 10,
        soldCount: 5,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should return products from remote data source', () async {
      // Arrange
      when(mockDataSource.fetchProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => testProducts);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result, equals(testProducts));
      verify(mockDataSource.fetchProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).called(1);
    });

    test('should pass parameters correctly to data source', () async {
      // Arrange
      const limit = 10;
      const cursor = 'cursor';
      const categoryId = 'cat1';
      const sortBy = 'price_low_high';
      final filters = {'minPrice': 100000};

      when(mockDataSource.fetchProducts(
        limit: limit,
        cursor: cursor,
        categoryId: categoryId,
        filters: filters,
        sortBy: sortBy,
      )).thenAnswer((_) async => testProducts);

      // Act
      await repository.getProducts(
        limit: limit,
        cursor: cursor,
        categoryId: categoryId,
        filters: filters,
        sortBy: sortBy,
      );

      // Assert
      verify(mockDataSource.fetchProducts(
        limit: limit,
        cursor: cursor,
        categoryId: categoryId,
        filters: filters,
        sortBy: sortBy,
      )).called(1);
    });

    test('should throw exception when data source fails', () async {
      // Arrange
      when(mockDataSource.fetchProducts(
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        categoryId: anyNamed('categoryId'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => repository.getProducts(),
        throwsException,
      );
    });
  });

  group('ProductRepositoryImpl - searchProducts', () {
    final testProducts = [
      Product(
        id: '1',
        shopId: 'shop1',
        categoryId: 'cat1',
        title: 'iPhone 15',
        description: 'Latest Apple phone',
        basePrice: 25000000,
        currency: 'VND',
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

    test('should return search results from data source', () async {
      // Arrange
      const query = 'iPhone';
      when(mockDataSource.searchProducts(
        query: query,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => testProducts);

      // Act
      final result = await repository.searchProducts(query: query);

      // Assert
      expect(result, equals(testProducts));
    });

    test('should return empty list when no results found', () async {
      // Arrange
      const query = 'nonexistent';
      when(mockDataSource.searchProducts(
        query: query,
        limit: anyNamed('limit'),
        cursor: anyNamed('cursor'),
        filters: anyNamed('filters'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await repository.searchProducts(query: query);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('ProductRepositoryImpl - getProductDetail', () {
    final testProduct = Product(
      id: '1',
      shopId: 'shop1',
      categoryId: 'cat1',
      title: 'Test Product',
      description: 'Description',
      basePrice: 100000,
      currency: 'VND',
      totalStock: 50,
      images: ['image1.jpg', 'image2.jpg'],
      condition: ProductCondition.newProduct,
      averageRating: 4.5,
      totalReviews: 10,
      soldCount: 5,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should return product detail from data source', () async {
      // Arrange
      const productId = '1';
      when(mockDataSource.fetchProductDetail(productId))
          .thenAnswer((_) async => testProduct);

      // Act
      final result = await repository.getProductDetail(productId);

      // Assert
      expect(result, equals(testProduct));
      verify(mockDataSource.fetchProductDetail(productId)).called(1);
    });

    test('should throw exception when product not found', () async {
      // Arrange
      const productId = 'nonexistent';
      when(mockDataSource.fetchProductDetail(productId))
          .thenThrow(Exception('Product not found'));

      // Act & Assert
      expect(
        () => repository.getProductDetail(productId),
        throwsException,
      );
    });
  });

  group('ProductRepositoryImpl - getCategories', () {
    final testCategories = [
      Category(
        id: '1',
        name: 'Electronics',
        iconUrl: 'electronics.png',
        parentId: null,
        level: 0,
        sortOrder: 1,
        isActive: true,
      ),
    ];

    test('should return categories from data source', () async {
      // Arrange
      when(mockDataSource.fetchCategories())
          .thenAnswer((_) async => testCategories);

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, equals(testCategories));
      verify(mockDataSource.fetchCategories()).called(1);
    });

    test('should throw exception when data source fails', () async {
      // Arrange
      when(mockDataSource.fetchCategories())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => repository.getCategories(),
        throwsException,
      );
    });
  });
}
