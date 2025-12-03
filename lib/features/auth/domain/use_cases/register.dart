import '../../../../core/models/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration.
///
/// Validates phone number format (Vietnamese), password strength,
/// and full name before calling repository.
class RegisterUseCase {
  /// Creates a RegisterUseCase instance.
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  /// Execute registration with validation.
  ///
  /// Phone number validation:
  /// - Must be 10 digits
  /// - Must start with 0
  /// - Or 11 digits starting with 84 (country code)
  ///
  /// Password validation:
  /// - Minimum 8 characters
  /// - Cannot be empty
  ///
  /// Full name validation:
  /// - Cannot be empty
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  /// - [Exception] if registration fails (phone already exists, network error)
  Future<User> execute({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    // Trim whitespace
    final trimmedPhone = phoneNumber.trim();
    final trimmedPassword = password.trim();
    final trimmedName = fullName.trim();

    // Validate full name
    if (trimmedName.isEmpty) {
      throw ArgumentError('Họ tên không được để trống');
    }

    // Validate password
    if (trimmedPassword.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }

    if (trimmedPassword.length < 8) {
      throw ArgumentError('Mật khẩu phải có ít nhất 8 ký tự');
    }

    // Normalize and validate phone number
    final normalizedPhone = _normalizePhoneNumber(trimmedPhone);
    if (!_isValidVietnamesePhone(normalizedPhone)) {
      throw ArgumentError('Số điện thoại không hợp lệ');
    }

    // Call repository
    return _repository.register(
      phoneNumber: normalizedPhone,
      password: trimmedPassword,
      fullName: trimmedName,
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

  /// Validate Vietnamese phone number format.
  ///
  /// Must be 10 digits starting with 0.
  bool _isValidVietnamesePhone(String phone) {
    if (phone.length != 10) return false;
    if (!phone.startsWith('0')) return false;

    // Valid prefixes: 03, 05, 07, 08, 09
    final validPrefixes = ['03', '05', '07', '08', '09'];
    final prefix = phone.substring(0, 2);

    return validPrefixes.contains(prefix);
  }
}
