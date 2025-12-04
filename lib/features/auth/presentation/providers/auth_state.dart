import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/user.dart';

part 'auth_state.freezed.dart';

/// Authentication state for the app.
@freezed
class AuthState with _$AuthState {
  /// Unauthenticated state - user not logged in.
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Authenticated state - user logged in.
  const factory AuthState.authenticated(User user) = _Authenticated;

  /// Loading state - authentication in progress.
  const factory AuthState.loading() = _Loading;

  /// Error state - authentication failed.
  const factory AuthState.error(String message) = _Error;
}
