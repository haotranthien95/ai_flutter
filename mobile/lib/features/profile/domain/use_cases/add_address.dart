import '../../../../core/models/address.dart';
import '../repositories/profile_repository.dart';

/// Use case for adding new shipping address.
///
/// Validates all required address fields and phone number format.
class AddAddressUseCase {
  /// Creates an AddAddressUseCase instance.
  const AddAddressUseCase(this._repository);

  final ProfileRepository _repository;

  /// Execute add address with validation.
  ///
  /// Address field validation:
  /// - All fields required except isDefault
  /// - recipientName: Cannot be empty
  /// - phoneNumber: Must be valid Vietnamese phone (10 digits starting with 0)
  /// - streetAddress: Cannot be empty
  /// - ward: Cannot be empty (Phường/Xã)
  /// - district: Cannot be empty (Quận/Huyện)
  /// - city: Cannot be empty (Thành phố/Tỉnh)
  /// - isDefault: Defaults to false if not provided
  ///
  /// Phone number normalization:
  /// - Converts +84xxxxxxxxx or 84xxxxxxxxx to 0xxxxxxxxx
  ///
  /// Returns created address.
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  /// - [Exception] if creation fails
  Future<Address> execute({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    // Trim all inputs
    final trimmedName = recipientName.trim();
    final trimmedPhone = phoneNumber.trim();
    final trimmedStreet = streetAddress.trim();
    final trimmedWard = ward.trim();
    final trimmedDistrict = district.trim();
    final trimmedCity = city.trim();

    // Validate recipient name
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tên người nhận không được để trống');
    }

    // Validate street address
    if (trimmedStreet.isEmpty) {
      throw ArgumentError('Địa chỉ không được để trống');
    }

    // Validate ward
    if (trimmedWard.isEmpty) {
      throw ArgumentError('Phường/Xã không được để trống');
    }

    // Validate district
    if (trimmedDistrict.isEmpty) {
      throw ArgumentError('Quận/Huyện không được để trống');
    }

    // Validate city
    if (trimmedCity.isEmpty) {
      throw ArgumentError('Thành phố/Tỉnh không được để trống');
    }

    // Normalize and validate phone number
    final normalizedPhone = _normalizePhoneNumber(trimmedPhone);
    if (!_isValidVietnamesePhone(normalizedPhone)) {
      throw ArgumentError('Số điện thoại không hợp lệ');
    }

    // Call repository
    return _repository.addAddress(
      recipientName: trimmedName,
      phoneNumber: normalizedPhone,
      streetAddress: trimmedStreet,
      ward: trimmedWard,
      district: trimmedDistrict,
      city: trimmedCity,
      isDefault: isDefault,
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
