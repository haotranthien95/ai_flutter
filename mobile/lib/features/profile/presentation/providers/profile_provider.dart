import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/address.dart';
import '../../domain/use_cases/get_user_profile.dart';
import '../../domain/use_cases/update_profile.dart';
import '../../domain/use_cases/add_address.dart';
import '../../domain/use_cases/update_address.dart';
import '../../domain/use_cases/delete_address.dart';
import '../../domain/use_cases/set_default_address.dart';
import '../../domain/repositories/profile_repository.dart';

/// Provider for profile use cases.
final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  throw UnimplementedError('GetUserProfileUseCase not configured');
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  throw UnimplementedError('UpdateProfileUseCase not configured');
});

final addAddressUseCaseProvider = Provider<AddAddressUseCase>((ref) {
  throw UnimplementedError('AddAddressUseCase not configured');
});

final updateAddressUseCaseProvider = Provider<UpdateAddressUseCase>((ref) {
  throw UnimplementedError('UpdateAddressUseCase not configured');
});

final deleteAddressUseCaseProvider = Provider<DeleteAddressUseCase>((ref) {
  throw UnimplementedError('DeleteAddressUseCase not configured');
});

final setDefaultAddressUseCaseProvider =
    Provider<SetDefaultAddressUseCase>((ref) {
  throw UnimplementedError('SetDefaultAddressUseCase not configured');
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('ProfileRepository not configured');
});

/// Provider for user profile.
final userProfileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<User>>((ref) {
  return ProfileNotifier(
    ref.watch(getUserProfileUseCaseProvider),
    ref.watch(updateProfileUseCaseProvider),
  );
});

/// Provider for user addresses.
final userAddressesProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressNotifier(
    ref.watch(profileRepositoryProvider),
    ref.watch(addAddressUseCaseProvider),
    ref.watch(updateAddressUseCaseProvider),
    ref.watch(deleteAddressUseCaseProvider),
    ref.watch(setDefaultAddressUseCaseProvider),
  );
});

/// Profile state notifier.
///
/// Manages user profile data and provides methods for updating profile.
class ProfileNotifier extends StateNotifier<AsyncValue<User>> {
  /// Creates a ProfileNotifier instance.
  ProfileNotifier(
    this._getUserProfileUseCase,
    this._updateProfileUseCase,
  ) : super(const AsyncValue.loading());

  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  /// Load user profile.
  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final user = await _getUserProfileUseCase.execute();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update user profile.
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _updateProfileUseCase.execute(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(user);
      return true;
    } on ArgumentError catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

/// Address state notifier.
///
/// Manages user addresses and provides methods for CRUD operations.
class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  /// Creates an AddressNotifier instance.
  AddressNotifier(
    this._repository,
    this._addAddressUseCase,
    this._updateAddressUseCase,
    this._deleteAddressUseCase,
    this._setDefaultAddressUseCase,
  ) : super(const AsyncValue.loading());

  final ProfileRepository _repository;
  final AddAddressUseCase _addAddressUseCase;
  final UpdateAddressUseCase _updateAddressUseCase;
  final DeleteAddressUseCase _deleteAddressUseCase;
  final SetDefaultAddressUseCase _setDefaultAddressUseCase;

  /// Load user addresses.
  Future<void> loadAddresses() async {
    state = const AsyncValue.loading();
    try {
      final addresses = await _repository.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add new address.
  Future<bool> addAddress({
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String ward,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    try {
      final address = await _addAddressUseCase.execute(
        recipientName: recipientName,
        phoneNumber: phoneNumber,
        streetAddress: streetAddress,
        ward: ward,
        district: district,
        city: city,
        isDefault: isDefault,
      );

      // Add to current list
      state.whenData((addresses) {
        state = AsyncValue.data([...addresses, address]);
      });

      return true;
    } on ArgumentError catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Update existing address.
  Future<bool> updateAddress({
    required String addressId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
  }) async {
    try {
      final updatedAddress = await _updateAddressUseCase(
        addressId: addressId,
        recipientName: recipientName,
        phoneNumber: phoneNumber,
        streetAddress: streetAddress,
        ward: ward,
        district: district,
        city: city,
      );

      // Update in current list
      state.whenData((addresses) {
        final updatedList = addresses.map((addr) {
          return addr.id == addressId ? updatedAddress : addr;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      return true;
    } on ArgumentError catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Delete address.
  Future<bool> deleteAddress(String addressId) async {
    try {
      await _deleteAddressUseCase(addressId);

      // Remove from current list
      state.whenData((addresses) {
        final updatedList =
            addresses.where((addr) => addr.id != addressId).toList();
        state = AsyncValue.data(updatedList);
      });

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Set address as default.
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final updatedAddress = await _setDefaultAddressUseCase(addressId);

      // Update in current list
      state.whenData((addresses) {
        final updatedList = addresses.map((addr) {
          if (addr.id == addressId) {
            return updatedAddress;
          } else if (addr.isDefault) {
            // Unset previous default
            return addr.copyWith(isDefault: false);
          }
          return addr;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
