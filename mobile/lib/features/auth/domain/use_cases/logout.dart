import '../repositories/auth_repository.dart';

/// Use case for user logout.
///
/// Clears authentication tokens and session data.
class LogoutUseCase {
  /// Creates a LogoutUseCase instance.
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Execute logout.
  ///
  /// Clears stored tokens and invalidates session.
  ///
  /// Throws:
  /// - [Exception] if logout fails (network error, etc.)
  Future<void> execute() async {
    return _repository.logout();
  }
}
