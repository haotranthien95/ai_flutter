import '../repositories/auth_repository.dart';

/// Use case for OTP verification.
///
/// Validates OTP code format before calling repository.
class VerifyOTPUseCase {
  /// Creates a VerifyOTPUseCase instance.
  const VerifyOTPUseCase(this._repository);

  final AuthRepository _repository;

  /// Execute OTP verification with validation.
  ///
  /// OTP validation:
  /// - Must be exactly 6 digits
  /// - Cannot be empty
  /// - Must contain only digits
  ///
  /// Phone number validation:
  /// - Cannot be empty
  ///
  /// Returns authentication tokens (access and refresh) on success.
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  /// - [Exception] if OTP is invalid or expired
  Future<Map<String, String>> execute({
    required String phoneNumber,
    required String otpCode,
  }) async {
    // Trim whitespace
    final trimmedPhone = phoneNumber.trim();
    final trimmedOTP = otpCode.trim();

    // Validate phone number
    if (trimmedPhone.isEmpty) {
      throw ArgumentError('Số điện thoại không được để trống');
    }

    // Validate OTP code
    if (trimmedOTP.isEmpty) {
      throw ArgumentError('Mã OTP không được để trống');
    }

    if (trimmedOTP.length != 6) {
      throw ArgumentError('Mã OTP phải có 6 chữ số');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(trimmedOTP)) {
      throw ArgumentError('Mã OTP chỉ được chứa số');
    }

    // Call repository
    return _repository.verifyOTP(
      phoneNumber: trimmedPhone,
      otpCode: trimmedOTP,
    );
  }
}
