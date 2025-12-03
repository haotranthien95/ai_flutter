import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/product_detail/presentation/product_detail_screen.dart';

/// Application routing configuration.
///
/// Defines all named routes and navigation structure using GoRouter.
class AppRouter {
  AppRouter._();

  /// Router instance.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      // Home route - Product discovery
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Search route
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Product detail route with dynamic ID
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),

      // TODO: Add more routes as features are implemented (US-002, US-003):
      // - /auth/login
      // - /auth/register  
      // - /cart
      // - /checkout
      // - /profile
      // - /orders
      // - /shop/:id (seller profile, US-006)
    ],
  );
}
