import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../domain/use_cases/register.dart';
import '../../domain/use_cases/verify_otp.dart';
import '../../domain/use_cases/login.dart';
import '../../domain/use_cases/logout.dart';
import '../../domain/use_cases/forgot_password.dart';
import '../../domain/use_cases/reset_password.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for authentication use cases.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  throw UnimplementedError('RegisterUseCase not configured');
});

final verifyOTPUseCaseProvider = Provider<VerifyOTPUseCase>((ref) {
  throw UnimplementedError('VerifyOTPUseCase not configured');
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  throw UnimplementedError('LoginUseCase not configured');
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  throw UnimplementedError('LogoutUseCase not configured');
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  throw UnimplementedError('ForgotPasswordUseCase not configured');
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  throw UnimplementedError('ResetPasswordUseCase not configured');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository not configured');
});

/// Provider for AuthNotifier.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(registerUseCaseProvider),
    ref.watch(verifyOTPUseCaseProvider),
    ref.watch(loginUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
    ref.watch(forgotPasswordUseCaseProvider),
    ref.watch(resetPasswordUseCaseProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Authentication state notifier.
///
/// Manages authentication state and provides methods for
/// registration, login, logout, and password reset.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates an AuthNotifier instance.
  AuthNotifier(
    this._registerUseCase,
    this._verifyOTPUseCase,
    this._loginUseCase,
    this._logoutUseCase,
    this._forgotPasswordUseCase,
    this._resetPasswordUseCase,
    this._authRepository,
  ) : super(const AuthState.unauthenticated()) {
    checkAuthStatus();
  }

  final RegisterUseCase _registerUseCase;
  final VerifyOTPUseCase _verifyOTPUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final AuthRepository _authRepository;

  /// Check current authentication status.
  ///
  /// Reads stored tokens and updates state accordingly.
  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = const AuthState.unauthenticated();
        }
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Register new user account.
  ///
  /// Returns registered user on success.
  /// State remains unauthenticated until OTP verification.
  Future<User?> register({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _registerUseCase(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
      );
      state = const AuthState.unauthenticated();
      return user;
    } on ArgumentError catch (e) {
      state = AuthState.error(e.message);
      return null;
    } catch (e) {
      state = AuthState.error(e.toString());
      return null;
    }
  }

  /// Verify OTP code and authenticate user.
  ///
  /// Updates state to authenticated on success.
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    state = const AuthState.loading();
    try {
      await _verifyOTPUseCase(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      // After OTP verification, check auth status to get user
      await checkAuthStatus();
      return true;
    } on ArgumentError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Login with credentials.
  ///
  /// Updates state to authenticated on success.
  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _loginUseCase(
        phoneNumber: phoneNumber,
        password: password,
      );
      state = AuthState.authenticated(user);
      return true;
    } on ArgumentError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logout current user.
  ///
  /// Clears tokens and updates state to unauthenticated.
  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _logoutUseCase();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout fails, clear local state
      state = const AuthState.unauthenticated();
    }
  }

  /// Request password reset OTP.
  ///
  /// Sends OTP to registered phone number.
  Future<bool> forgotPassword({
    required String phoneNumber,
  }) async {
    state = const AuthState.loading();
    try {
      await _forgotPasswordUseCase(phoneNumber: phoneNumber);
      state = const AuthState.unauthenticated();
      return true;
    } on ArgumentError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Reset password with OTP verification.
  ///
  /// User must login again after password reset.
  Future<bool> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    state = const AuthState.loading();
    try {
      await _resetPasswordUseCase(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        newPassword: newPassword,
      );
      state = const AuthState.unauthenticated();
      return true;
    } on ArgumentError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }
}
