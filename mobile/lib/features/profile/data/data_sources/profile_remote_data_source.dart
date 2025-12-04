import 'package:dio/dio.dart';
import '../../../../core/models/address.dart';
import '../../../../core/models/user.dart';

/// Remote data source for profile operations.
///
/// Communicates with backend API for user profile and address management.
class ProfileRemoteDataSource {
  /// Creates a ProfileRemoteDataSource instance.
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  /// Get current user profile.
  ///
  /// GET /profile
  ///
  /// Returns user profile data.
  ///
  /// Throws:
  /// - [DioException] with 401 status if not authenticated
  Future<User> getUserProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profile');
    return User.fromJson(response.data!);
  }

  /// Update user profile.
  ///
  /// PUT /profile
  ///
  /// Returns updated user data.
  ///
  /// Throws:
  /// - [DioException] with 400 status if validation fails
  Future<User> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/profile',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );

    return User.fromJson(response.data!);
  }

  /// Get user addresses.
  ///
  /// GET /profile/addresses
  ///
  /// Returns list of saved addresses.
  Future<List<Address>> getAddresses() async {
    final response = await _dio.get<List<dynamic>>('/profile/addresses');
    return response.data!
        .map((json) => Address.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Add new address.
  ///
  /// POST /profile/addresses
  ///
  /// Returns created address.
  ///
  /// Throws:
  /// - [DioException] with 400 status if validation fails
  Future<Address> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/profile/addresses',
      data: {
        'recipientName': recipientName,
        'phoneNumber': phoneNumber,
        'streetAddress': streetAddress,
        'ward': ward,
        'district': district,
        'city': city,
        'isDefault': isDefault,
      },
    );

    return Address.fromJson(response.data!);
  }

  /// Update existing address.
  ///
  /// PUT /profile/addresses/:id
  ///
  /// Returns updated address.
  ///
  /// Throws:
  /// - [DioException] with 404 status if address not found
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
    final response = await _dio.put<Map<String, dynamic>>(
      '/profile/addresses/$addressId',
      data: {
        if (recipientName != null) 'recipientName': recipientName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (streetAddress != null) 'streetAddress': streetAddress,
        if (ward != null) 'ward': ward,
        if (district != null) 'district': district,
        if (city != null) 'city': city,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );

    return Address.fromJson(response.data!);
  }

  /// Delete address.
  ///
  /// DELETE /profile/addresses/:id
  ///
  /// Throws:
  /// - [DioException] with 404 status if address not found
  /// - [DioException] with 400 status if trying to delete default address
  Future<void> deleteAddress({
    required String addressId,
  }) async {
    await _dio.delete<void>('/profile/addresses/$addressId');
  }

  /// Set address as default.
  ///
  /// POST /profile/addresses/:id/set-default
  ///
  /// Returns updated address.
  ///
  /// Throws:
  /// - [DioException] with 404 status if address not found
  Future<Address> setDefaultAddress({
    required String addressId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/profile/addresses/$addressId/set-default',
    );

    return Address.fromJson(response.data!);
  }
}
