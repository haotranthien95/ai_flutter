import '../../../../core/models/user.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting user profile.
///
/// Retrieves current authenticated user's profile information.
class GetUserProfileUseCase {
  /// Creates a GetUserProfileUseCase instance.
  const GetUserProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Execute get user profile.
  ///
  /// Returns current user's profile data.
  ///
  /// Throws:
  /// - [Exception] if user not found or unauthorized
  Future<User> execute() async {
    return _repository.getUserProfile();
  }
}
