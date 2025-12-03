import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/features/home/domain/use_cases/get_categories.dart';
import 'package:ai_flutter/core/models/category.dart';

@GenerateMocks([ProductRepository])
import 'get_categories_test.mocks.dart';

void main() {
  late GetCategoriesUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetCategoriesUseCase(mockRepository);
  });

  group('GetCategoriesUseCase', () {
    final testCategories = [
      Category(
        id: '1',
        name: 'Electronics',
        iconUrl: 'electronics.png',
        parentId: null,
        level: 0,
        sortOrder: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '2',
        name: 'Fashion',
        iconUrl: 'fashion.png',
        parentId: null,
        level: 0,
        sortOrder: 2,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '3',
        name: 'Smartphones',
        iconUrl: 'phones.png',
        parentId: '1',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should fetch all categories successfully', () async {
      // Arrange
      when(mockRepository.getCategories())
          .thenAnswer((_) async => testCategories);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(testCategories));
      verify(mockRepository.getCategories()).called(1);
    });

    test('should return only root categories when filtering', () async {
      // Arrange
      final rootCategories = testCategories.where((c) => c.isRoot).toList();
      when(mockRepository.getCategories())
          .thenAnswer((_) async => testCategories);

      // Act
      final result = await useCase.execute();
      final filtered = result.where((c) => c.isRoot).toList();

      // Assert
      expect(filtered.length, equals(2));
      expect(filtered.every((c) => c.parentId == null), isTrue);
    });

    test('should return empty list when no categories exist', () async {
      // Arrange
      when(mockRepository.getCategories()).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isEmpty);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getCategories())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsException,
      );
    });

    test('should handle hierarchical category structure', () async {
      // Arrange
      when(mockRepository.getCategories())
          .thenAnswer((_) async => testCategories);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.length, equals(3));

      // Check root categories
      final rootCategories = result.where((c) => c.isRoot).toList();
      expect(rootCategories.length, equals(2));

      // Check subcategories
      final subCategories = result.where((c) => c.isSubcategory).toList();
      expect(subCategories.length, equals(1));
      expect(subCategories.first.parentId, equals('1'));
    });

    test('should return only active categories', () async {
      // Arrange
      final mixedCategories = [
        ...testCategories,
        Category(
          id: '4',
          name: 'Inactive Category',
          iconUrl: 'inactive.png',
          parentId: null,
          level: 0,
          sortOrder: 3,
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      when(mockRepository.getCategories())
          .thenAnswer((_) async => mixedCategories);

      // Act
      final result = await useCase.execute();
      final activeOnly = result.where((c) => c.isActive).toList();

      // Assert
      expect(activeOnly.length, equals(3));
      expect(activeOnly.every((c) => c.isActive), isTrue);
    });
  });
}
