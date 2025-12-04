import '../../../../core/models/user.dart';
import '../../../../core/models/address.dart';

/// Profile repository interface.
///
/// Defines contract for user profile and address management operations.
abstract class ProfileRepository {
  /// Get current authenticated user's profile.
  ///
  /// Throws:
  /// - [Exception] if user not found or unauthorized
  Future<User> getUserProfile();

  /// Update user profile information.
  ///
  /// All parameters are optional. Only provided fields will be updated.
  ///
  /// Throws:
  /// - [Exception] if update fails or unauthorized
  Future<User> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  });

  /// Get all addresses for current user.
  Future<List<Address>> getAddresses();

  /// Add new shipping address.
  ///
  /// If this is the first address, it will automatically be set as default.
  ///
  /// Throws:
  /// - [Exception] if creation fails
  Future<Address> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  });

  /// Update existing address.
  ///
  /// Throws:
  /// - [Exception] if address not found or unauthorized
  Future<Address> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  });

  /// Delete address.
  ///
  /// Cannot delete the default address if it's the only address.
  ///
  /// Throws:
  /// - [Exception] if deletion fails or address not found
  Future<void> deleteAddress(String addressId);

  /// Set address as default shipping address.
  ///
  /// Automatically unsets previous default address.
  ///
  /// Throws:
  /// - [Exception] if address not found
  Future<Address> setDefaultAddress(String addressId);
}
