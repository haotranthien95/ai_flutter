import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'app/providers.dart';
import 'core/services/connectivity_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';

/// Application entry point.
void main() {
  // Initialize connectivity monitoring
  ConnectivityService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Auth providers (Phase 4)
        authRepositoryProvider
            .overrideWith((ref) => ref.watch(authRepositoryProviderImpl)),
        registerUseCaseProvider
            .overrideWith((ref) => ref.watch(registerUseCaseProviderImpl)),
        verifyOTPUseCaseProvider
            .overrideWith((ref) => ref.watch(verifyOTPUseCaseProviderImpl)),
        loginUseCaseProvider
            .overrideWith((ref) => ref.watch(loginUseCaseProviderImpl)),
        logoutUseCaseProvider
            .overrideWith((ref) => ref.watch(logoutUseCaseProviderImpl)),
        forgotPasswordUseCaseProvider.overrideWith(
            (ref) => ref.watch(forgotPasswordUseCaseProviderImpl)),
        resetPasswordUseCaseProvider
            .overrideWith((ref) => ref.watch(resetPasswordUseCaseProviderImpl)),

        // Profile providers (Phase 4)
        profileRepositoryProvider
            .overrideWith((ref) => ref.watch(profileRepositoryProviderImpl)),
        getUserProfileUseCaseProvider.overrideWith(
            (ref) => ref.watch(getUserProfileUseCaseProviderImpl)),
        updateProfileUseCaseProvider
            .overrideWith((ref) => ref.watch(updateProfileUseCaseProviderImpl)),
        addAddressUseCaseProvider
            .overrideWith((ref) => ref.watch(addAddressUseCaseProviderImpl)),
        updateAddressUseCaseProvider
            .overrideWith((ref) => ref.watch(updateAddressUseCaseProviderImpl)),
        deleteAddressUseCaseProvider
            .overrideWith((ref) => ref.watch(deleteAddressUseCaseProviderImpl)),
        setDefaultAddressUseCaseProvider.overrideWith(
            (ref) => ref.watch(setDefaultAddressUseCaseProviderImpl)),

        // Cart providers (Phase 5)
        getCartUseCaseProvider
            .overrideWith((ref) => ref.watch(getCartUseCaseProviderImpl)),
        addToCartUseCaseProvider
            .overrideWith((ref) => ref.watch(addToCartUseCaseProviderImpl)),
        updateCartItemQuantityUseCaseProvider.overrideWith(
            (ref) => ref.watch(updateCartItemQuantityUseCaseProviderImpl)),
        removeCartItemUseCaseProvider.overrideWith(
            (ref) => ref.watch(removeCartItemUseCaseProviderImpl)),
      ],
      child: const MyApp(),
    ),
  );
}

/// Root application widget.
class MyApp extends StatelessWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Flutter Marketplace',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
