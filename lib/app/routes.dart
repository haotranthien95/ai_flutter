import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/product_detail/presentation/product_detail_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';
import '../features/cart/presentation/address_selector_screen.dart';
import '../features/cart/presentation/order_confirmation_screen.dart';

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

      // Cart route
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),

      // Checkout route
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // Address selector route
      GoRoute(
        path: '/checkout/address',
        name: 'address-selector',
        builder: (context, state) => const AddressSelectorScreen(),
      ),

      // Order confirmation route
      GoRoute(
        path: '/order/confirmation/:orderId',
        name: 'order-confirmation',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),

      // TODO: Add more routes as features are implemented (US-002, US-003):
      // - /auth/login
      // - /auth/register
      // - /profile
      // - /orders
      // - /shop/:id (seller profile, US-006)
    ],
  );
}

/// Route path constants for easy reference
class Routes {
  Routes._();

  static const String home = '/';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String addressSelector = '/checkout/address';
  static const String orderConfirmation = '/order/confirmation';

  static String productDetail(String id) => '/product/$id';
  static String orderConfirmationWithId(String orderId) =>
      '/order/confirmation/$orderId';
}
