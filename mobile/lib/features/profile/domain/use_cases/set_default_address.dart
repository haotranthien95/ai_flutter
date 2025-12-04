import '../../../../core/models/address.dart';
import '../repositories/profile_repository.dart';

/// Use case for setting an address as default.
///
/// Validates address ID before setting as default.
class SetDefaultAddressUseCase {
  /// Creates a SetDefaultAddressUseCase instance.
  SetDefaultAddressUseCase(this._repository);

  final ProfileRepository _repository;

  /// Set address as default by ID.
  ///
  /// Validates:
  /// - addressId is not empty
  ///
  /// Throws:
  /// - [ArgumentError] if addressId is empty
  Future<Address> call(String addressId) async {
    if (addressId.isEmpty) {
      throw ArgumentError('Address ID cannot be empty');
    }

    return _repository.setDefaultAddress(addressId);
  }
}
