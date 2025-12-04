import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ai_flutter/core/models/address.dart';
import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/update_address.dart';

import 'update_address_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late UpdateAddressUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateAddressUseCase(mockRepository);
  });

  group('UpdateAddressUseCase', () {
    const testAddressId = 'addr_123';
    const testRecipientName = 'Updated Name';
    const testPhone = '0987654321';
    const testStreet = '456 Updated St';

    final mockAddress = Address(
      id: testAddressId,
      userId: 'user_123',
      recipientName: testRecipientName,
      phoneNumber: testPhone,
      streetAddress: testStreet,
      ward: 'Ward 2',
      district: 'District 2',
      city: 'HCMC',
      isDefault: false,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should call repository with valid data', () async {
      // Arrange
      when(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
      )).thenAnswer((_) async => mockAddress);

      // Act
      final result = await useCase(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
      );

      // Assert
      expect(result, mockAddress);
      verify(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
      )).called(1);
    });

    test('should normalize phone number with 84 prefix', () async {
      // Arrange
      when(mockRepository.updateAddress(
        addressId: testAddressId,
        phoneNumber: testPhone,
      )).thenAnswer((_) async => mockAddress);

      // Act
      await useCase(
        addressId: testAddressId,
        phoneNumber: '84987654321',
      );

      // Assert
      verify(mockRepository.updateAddress(
        addressId: testAddressId,
        phoneNumber: testPhone,
      )).called(1);
    });

    test('should throw ArgumentError when addressId is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          addressId: '',
          recipientName: testRecipientName,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Address ID cannot be empty',
          ),
        ),
      );
    });

    test('should throw ArgumentError when no fields provided', () async {
      // Act & Assert
      expect(
        () => useCase(addressId: testAddressId),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'At least one field must be provided for update',
          ),
        ),
      );
    });

    test('should throw ArgumentError for invalid phone format', () async {
      // Act & Assert
      expect(
        () => useCase(
          addressId: testAddressId,
          phoneNumber: '0187654321',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid Vietnamese phone number format'),
          ),
        ),
      );
    });

    test('should update single field (recipientName)', () async {
      // Arrange
      when(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
      )).thenAnswer((_) async => mockAddress);

      // Act
      await useCase(
        addressId: testAddressId,
        recipientName: testRecipientName,
      );

      // Assert
      verify(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
      )).called(1);
    });

    test('should update multiple fields', () async {
      // Arrange
      when(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
        streetAddress: testStreet,
        ward: 'New Ward',
        district: 'New District',
        city: 'New City',
      )).thenAnswer((_) async => mockAddress);

      // Act
      await useCase(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
        streetAddress: testStreet,
        ward: 'New Ward',
        district: 'New District',
        city: 'New City',
      );

      // Assert
      verify(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        phoneNumber: testPhone,
        streetAddress: testStreet,
        ward: 'New Ward',
        district: 'New District',
        city: 'New City',
      )).called(1);
    });

    test('should allow updating without phone number', () async {
      // Arrange
      when(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        streetAddress: testStreet,
      )).thenAnswer((_) async => mockAddress);

      // Act
      await useCase(
        addressId: testAddressId,
        recipientName: testRecipientName,
        streetAddress: testStreet,
      );

      // Assert
      verify(mockRepository.updateAddress(
        addressId: testAddressId,
        recipientName: testRecipientName,
        streetAddress: testStreet,
      )).called(1);
    });
  });
}
