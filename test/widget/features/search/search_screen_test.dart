import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/features/search/presentation/search_screen.dart';
import 'package:ai_flutter/features/search/presentation/search_provider.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/widgets/product_card.dart';
import 'package:ai_flutter/core/widgets/loading_indicator.dart';
import 'package:ai_flutter/core/widgets/empty_state.dart';

void main() {
  group('SearchScreen Widget Tests', () {
    late List<Product> testSearchResults;
    late List<String> testSuggestions;

    setUp(() {
      testSearchResults = [
        Product(
          id: '1',
          shopId: 'shop1',
          categoryId: 'cat1',
          title: 'iPhone 15 Pro Max',
          description: 'Latest Apple phone',
          basePrice: 29990000,
          totalStock: 50,
          images: ['iphone.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.8,
          totalReviews: 100,
          soldCount: 50,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Product(
          id: '2',
          shopId: 'shop2',
          categoryId: 'cat1',
          title: 'iPhone 14 Pro',
          description: 'Previous generation',
          basePrice: 24990000,
          totalStock: 30,
          images: ['iphone14.jpg'],
          condition: ProductCondition.newProduct,
          averageRating: 4.7,
          totalReviews: 80,
          soldCount: 40,
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      testSuggestions = [
        'iPhone 15',
        'iPhone 14',
        'iPhone Pro Max',
        'iPhone accessories',
      ];
    });

    testWidgets('should display search bar with hint text', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm kiếm sản phẩm...'), findsOneWidget);
    });

    testWidgets('should display autocomplete suggestions on typing',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..suggestions = testSuggestions
                ..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Suggestions should appear in dropdown
      expect(find.text('iPhone 15'), findsOneWidget);
      expect(find.text('iPhone 14'), findsOneWidget);
      expect(find.text('iPhone Pro Max'), findsOneWidget);
    });

    testWidgets('should display search results in grid', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..searchResults = AsyncValue.data(testSearchResults)
                ..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
      expect(find.text('iPhone 14 Pro'), findsOneWidget);
    });

    testWidgets('should display filter button in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should display sort button in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('should open filter dialog when filter button tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Bộ lọc'), findsOneWidget);
    });

    testWidgets('should open sort dialog when sort button tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Sắp xếp theo'), findsOneWidget);
      expect(find.text('Liên quan nhất'), findsOneWidget);
      expect(find.text('Mới nhất'), findsOneWidget);
      expect(find.text('Bán chạy nhất'), findsOneWidget);
      expect(find.text('Giá: Thấp đến cao'), findsOneWidget);
      expect(find.text('Giá: Cao đến thấp'), findsOneWidget);
      expect(find.text('Đánh giá cao nhất'), findsOneWidget);
    });

    testWidgets('should display loading indicator during search',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..searchResults = const AsyncValue.loading()
                ..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no results found',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..searchResults = const AsyncValue.data([])
                ..query = 'nonexistent product',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EmptySearchResults), findsOneWidget);
      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
    });

    testWidgets('should trigger search when suggestion tapped', (tester) async {
      // Arrange
      bool searchTriggered = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..suggestions = testSuggestions
                ..query = 'iPhone'
                ..onSearch = (query) {
                  searchTriggered = true;
                },
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('iPhone 15'));
      await tester.pumpAndSettle();

      // Assert
      expect(searchTriggered, isTrue);
    });

    testWidgets('should clear search when clear icon tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should debounce search input', (tester) async {
      // Arrange
      int searchCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..onSearch = (query) {
                  searchCount++;
                },
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Act - Type multiple characters quickly
      await tester.enterText(find.byType(TextField), 'i');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'iP');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'iPh');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'iPhon');

      // Wait for debounce period
      await tester.pump(const Duration(milliseconds: 300));

      // Assert - Should only trigger search once after debounce
      expect(searchCount, equals(1));
    });

    testWidgets('should display result count', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..searchResults = AsyncValue.data(testSearchResults)
                ..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2 kết quả'), findsOneWidget);
    });

    testWidgets('should support pagination on scroll', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchProviderProvider.overrideWith(
              (ref) => SearchProvider()
                ..searchResults = AsyncValue.data(testSearchResults)
                ..query = 'iPhone',
            ),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Scroll to bottom
      await tester.drag(find.byType(GridView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Assert - Should trigger load more (implementation-specific)
      expect(tester.takeException(), isNull);
    });
  });
}
