import '../../../../core/models/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login.
///
/// Validates phone number and password before calling repository.
class LoginUseCase {
  /// Creates a LoginUseCase instance.
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Execute login with validation.
  ///
  /// Phone number validation:
  /// - Cannot be empty
  /// - Normalized to Vietnamese format (0xxxxxxxxx)
  ///
  /// Password validation:
  /// - Cannot be empty
  ///
  /// Returns authenticated user data with tokens stored.
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  /// - [Exception] if credentials are invalid (401 unauthorized)
  /// - [Exception] if account is suspended
  Future<User> execute({
    required String phoneNumber,
    required String password,
  }) async {
    // Trim whitespace
    final trimmedPhone = phoneNumber.trim();
    final trimmedPassword = password.trim();

    // Validate phone number
    if (trimmedPhone.isEmpty) {
      throw ArgumentError('Số điện thoại không được để trống');
    }

    // Validate password
    if (trimmedPassword.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }

    // Normalize phone number
    final normalizedPhone = _normalizePhoneNumber(trimmedPhone);

    // Call repository
    return _repository.login(
      phoneNumber: normalizedPhone,
      password: trimmedPassword,
    );
  }

  /// Normalize phone number to Vietnamese format (0xxxxxxxxx).
  ///
  /// Converts +84xxxxxxxxx or 84xxxxxxxxx to 0xxxxxxxxx.
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // If starts with 84, convert to 0
    if (digitsOnly.startsWith('84') && digitsOnly.length == 11) {
      return '0${digitsOnly.substring(2)}';
    }

    return digitsOnly;
  }
}
