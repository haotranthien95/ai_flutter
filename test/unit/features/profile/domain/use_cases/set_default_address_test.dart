import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ai_flutter/core/models/address.dart';
import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/set_default_address.dart';

import 'set_default_address_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late SetDefaultAddressUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = SetDefaultAddressUseCase(mockRepository);
  });

  group('SetDefaultAddressUseCase', () {
    const testAddressId = 'addr_123';

    final mockAddress = Address(
      id: testAddressId,
      userId: 'user_123',
      recipientName: 'Test User',
      phoneNumber: '0987654321',
      streetAddress: '123 Test St',
      ward: 'Ward 1',
      district: 'District 1',
      city: 'HCMC',
      isDefault: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should call repository with valid address ID', () async {
      // Arrange
      when(mockRepository.setDefaultAddress(testAddressId))
          .thenAnswer((_) async => mockAddress);

      // Act
      final result = await useCase(testAddressId);

      // Assert
      expect(result, mockAddress);
      expect(result.isDefault, true);
      verify(mockRepository.setDefaultAddress(testAddressId)).called(1);
    });

    test('should throw ArgumentError when addressId is empty', () async {
      // Act & Assert
      expect(
        () => useCase(''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Address ID cannot be empty',
          ),
        ),
      );
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.setDefaultAddress(testAddressId))
          .thenThrow(Exception('Address not found'));

      // Act & Assert
      expect(
        () => useCase(testAddressId),
        throwsException,
      );
    });
  });
}
