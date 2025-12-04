import '../repositories/auth_repository.dart';

/// Use case for requesting password reset OTP.
///
/// Validates phone number and sends OTP for password reset.
class ForgotPasswordUseCase {
  /// Creates a ForgotPasswordUseCase instance.
  ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  /// Vietnamese phone number regex pattern.
  static final _phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');

  /// Request password reset OTP.
  ///
  /// Validates:
  /// - Phone number is not empty
  /// - Phone number matches Vietnamese format (10 digits, starts with 0)
  ///
  /// Throws:
  /// - [ArgumentError] if phone number is empty or invalid format
  Future<void> call({
    required String phoneNumber,
  }) async {
    // Validate phone number not empty
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    // Normalize phone number (remove +84 prefix if exists)
    final normalizedPhone = phoneNumber.startsWith('84')
        ? '0${phoneNumber.substring(2)}'
        : phoneNumber;

    // Validate Vietnamese phone format
    if (!_phoneRegex.hasMatch(normalizedPhone)) {
      throw ArgumentError(
        'Invalid Vietnamese phone number format. Must be 10 digits starting with 0',
      );
    }

    return _repository.forgotPassword(phoneNumber: normalizedPhone);
  }
}
