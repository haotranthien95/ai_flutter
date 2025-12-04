import '../../../../core/models/address.dart';
import '../../../../core/models/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_remote_data_source.dart';

/// Implementation of ProfileRepository.
///
/// Delegates to remote data source for profile and address operations.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Creates a ProfileRepositoryImpl instance.
  ProfileRepositoryImpl(this._dataSource);

  final ProfileRemoteDataSource _dataSource;

  @override
  Future<User> getUserProfile() async {
    return _dataSource.getUserProfile();
  }

  @override
  Future<User> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    return _dataSource.updateProfile(
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<List<Address>> getAddresses() async {
    return _dataSource.getAddresses();
  }

  @override
  Future<Address> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    return _dataSource.addAddress(
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      ward: ward,
      district: district,
      city: city,
      isDefault: isDefault,
    );
  }

  @override
  Future<Address> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  }) async {
    return _dataSource.updateAddress(
      addressId: addressId,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      ward: ward,
      district: district,
      city: city,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    return _dataSource.deleteAddress(addressId: addressId);
  }

  @override
  Future<Address> setDefaultAddress(String addressId) async {
    return _dataSource.setDefaultAddress(addressId: addressId);
  }
}
