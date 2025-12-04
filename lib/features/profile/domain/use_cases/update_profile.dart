import '../../../../core/models/user.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating user profile.
///
/// Validates email format and ensures full name is not empty.
class UpdateProfileUseCase {
  /// Creates an UpdateProfileUseCase instance.
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Execute profile update with validation.
  ///
  /// Full name validation:
  /// - Cannot be empty
  ///
  /// Email validation:
  /// - Must be valid email format if provided
  /// - Can be null to clear email
  ///
  /// Avatar URL validation:
  /// - Can be any valid URL or null
  ///
  /// Returns updated user data.
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  /// - [Exception] if update fails
  Future<User> execute({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    // Trim inputs if not null
    final trimmedName = fullName?.trim();
    final trimmedEmail = email?.trim();
    final trimmedAvatarUrl = avatarUrl?.trim();

    // Validate full name if provided
    if (trimmedName != null && trimmedName.isEmpty) {
      throw ArgumentError('Họ tên không được để trống');
    }

    // Validate email format if provided
    if (trimmedEmail != null &&
        trimmedEmail.isNotEmpty &&
        !_isValidEmail(trimmedEmail)) {
      throw ArgumentError('Email không hợp lệ');
    }

    // Call repository
    return _repository.updateProfile(
      fullName: trimmedName,
      email: trimmedEmail,
      avatarUrl: trimmedAvatarUrl,
    );
  }

  /// Validate email format.
  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
