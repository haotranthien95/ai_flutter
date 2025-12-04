import '../repositories/auth_repository.dart';

/// Use case for resetting password with OTP verification.
///
/// Validates OTP code and new password before resetting.
class ResetPasswordUseCase {
  /// Creates a ResetPasswordUseCase instance.
  ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  /// Vietnamese phone number regex pattern.
  static final _phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');

  /// OTP code regex (6 digits).
  static final _otpRegex = RegExp(r'^\d{6}$');

  /// Reset password with OTP verification.
  ///
  /// Validates:
  /// - Phone number is not empty and matches Vietnamese format
  /// - OTP code is exactly 6 digits
  /// - New password is at least 8 characters
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  Future<void> call({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    // Validate phone number
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    final normalizedPhone = phoneNumber.startsWith('84')
        ? '0${phoneNumber.substring(2)}'
        : phoneNumber;

    if (!_phoneRegex.hasMatch(normalizedPhone)) {
      throw ArgumentError(
        'Invalid Vietnamese phone number format. Must be 10 digits starting with 0',
      );
    }

    // Validate OTP code
    if (otpCode.isEmpty) {
      throw ArgumentError('OTP code cannot be empty');
    }

    if (!_otpRegex.hasMatch(otpCode)) {
      throw ArgumentError('OTP code must be exactly 6 digits');
    }

    // Validate new password
    if (newPassword.isEmpty) {
      throw ArgumentError('New password cannot be empty');
    }

    if (newPassword.length < 8) {
      throw ArgumentError('New password must be at least 8 characters long');
    }

    return _repository.resetPassword(
      phoneNumber: normalizedPhone,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }
}
