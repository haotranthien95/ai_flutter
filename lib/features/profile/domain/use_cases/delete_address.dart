import '../repositories/profile_repository.dart';

/// Use case for deleting an address.
///
/// Validates address ID before deletion.
class DeleteAddressUseCase {
  /// Creates a DeleteAddressUseCase instance.
  DeleteAddressUseCase(this._repository);

  final ProfileRepository _repository;

  /// Delete address by ID.
  ///
  /// Validates:
  /// - addressId is not empty
  ///
  /// Throws:
  /// - [ArgumentError] if addressId is empty
  Future<void> call(String addressId) async {
    if (addressId.isEmpty) {
      throw ArgumentError('Address ID cannot be empty');
    }

    return _repository.deleteAddress(addressId);
  }
}
