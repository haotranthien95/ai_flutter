import 'package:go_router/go_router.dart';

import '../features/home/screens/home_screen.dart';

/// Application routing configuration.
///
/// Defines all named routes and navigation structure using GoRouter.
class AppRouter {
  AppRouter._();

  /// Router instance.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // TODO: Add more routes as features are implemented:
      // - /auth/login
      // - /auth/register
      // - /products/:id
      // - /cart
      // - /checkout
      // - /profile
      // - /orders
      // - /search
    ],
  );
}
