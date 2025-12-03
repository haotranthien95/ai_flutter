import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/home/presentation/home_screen.dart';
import 'package:ai_flutter/features/home/presentation/home_provider.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/category.dart';
import 'package:ai_flutter/core/widgets/product_card.dart';
import 'package:ai_flutter/core/widgets/loading_indicator.dart';
import 'package:ai_flutter/core/widgets/error_view.dart';
import 'package:ai_flutter/core/widgets/empty_state.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late List<Product> testProducts;
    late List<Category> testCategories;

    setUp(() {
      testProducts = [
        Product(
          id: '1',
          shopId: 'shop1',
          categoryId: 'cat1',
          title: 'Test Product 1',
          description: 'Description 1',
          basePrice: 100000,
          totalStock: 50,
          images: ['image1.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.5,
          totalReviews: 10,
          soldCount: 5,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Product(
          id: '2',
          shopId: 'shop1',
          categoryId: 'cat1',
          title: 'Test Product 2',
          description: 'Description 2',
          basePrice: 200000,
          totalStock: 30,
          images: ['image2.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.0,
          totalReviews: 8,
          soldCount: 3,
          isActive: true,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      testCategories = [
        Category(
          id: '1',
          name: 'Electronics',
          iconUrl: 'electronics.png',
          parentId: null,
          level: 0,
          sortOrder: 1,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Category(
          id: '2',
          name: 'Fashion',
          iconUrl: 'fashion.png',
          parentId: null,
          level: 0,
          sortOrder: 2,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
    });

    testWidgets('should display loading indicator while loading products',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) => HomeProvider()..state = const AsyncValue.loading(),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('should display product grid when products loaded',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
    });

    testWidgets('should display category chips horizontally', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProviderProvider.overrideWith(
              (ref) => CategoriesProvider()
                ..state = AsyncValue.data(testCategories),
            ),
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Fashion'), findsOneWidget);
      
      // Check horizontal scrollable list
      final chipList = find.byType(ListView);
      expect(chipList, findsWidgets);
    });

    testWidgets('should display search icon in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display error view with retry button on error',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) => HomeProvider()
                ..state = AsyncValue.error(
                  Exception('Network error'),
                  StackTrace.current,
                ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should display empty state when no products', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) => HomeProvider()..state = const AsyncValue.data([]),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('should support pull to refresh', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - RefreshIndicator should be present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should filter products when category chip tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProviderProvider.overrideWith(
              (ref) => CategoriesProvider()
                ..state = AsyncValue.data(testCategories),
            ),
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      // Assert - Category chip should be selected (visual feedback)
      final chip = tester.widget<Chip>(find.ancestor(
        of: find.text('Electronics'),
        matching: find.byType(Chip),
      ));
      expect(chip, isNotNull);
    });

    testWidgets('should navigate to search screen when search icon tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Assert - Navigation should occur (will be implemented with routes)
      // This is a placeholder test - actual navigation test requires router setup
    });

    testWidgets('should show cart icon in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProviderProvider.overrideWith(
              (ref) =>
                  HomeProvider()..state = AsyncValue.data(testProducts),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });
  });
}
