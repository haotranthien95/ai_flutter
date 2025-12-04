import '../../../../core/models/address.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating an existing address.
///
/// Validates address fields and updates the address.
class UpdateAddressUseCase {
  /// Creates an UpdateAddressUseCase instance.
  UpdateAddressUseCase(this._repository);

  final ProfileRepository _repository;

  /// Vietnamese phone number regex pattern.
  static final _phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');

  /// Update existing address.
  ///
  /// Validates:
  /// - addressId is not empty
  /// - If phoneNumber provided, must match Vietnamese format
  /// - At least one field must be provided for update
  ///
  /// Throws:
  /// - [ArgumentError] if validation fails
  Future<Address> call({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
  }) async {
    // Validate addressId
    if (addressId.isEmpty) {
      throw ArgumentError('Address ID cannot be empty');
    }

    // Check at least one field is provided
    if (recipientName == null &&
        phoneNumber == null &&
        streetAddress == null &&
        ward == null &&
        district == null &&
        city == null) {
      throw ArgumentError('At least one field must be provided for update');
    }

    // Validate phone number if provided
    if (phoneNumber != null) {
      final normalizedPhone = phoneNumber.startsWith('84')
          ? '0${phoneNumber.substring(2)}'
          : phoneNumber;

      if (!_phoneRegex.hasMatch(normalizedPhone)) {
        throw ArgumentError(
          'Invalid Vietnamese phone number format. Must be 10 digits starting with 0',
        );
      }

      return _repository.updateAddress(
        addressId: addressId,
        recipientName: recipientName,
        phoneNumber: normalizedPhone,
        streetAddress: streetAddress,
        ward: ward,
        district: district,
        city: city,
      );
    }

    return _repository.updateAddress(
      addressId: addressId,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      ward: ward,
      district: district,
      city: city,
    );
  }
}
