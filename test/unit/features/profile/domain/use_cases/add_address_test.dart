import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/add_address.dart';
import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/core/models/address.dart';

@GenerateMocks([ProfileRepository])
import 'add_address_test.mocks.dart';

void main() {
  late AddAddressUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = AddAddressUseCase(mockRepository);
  });

  group('AddAddressUseCase', () {
    const validRecipientName = 'Nguyễn Văn A';
    const validPhoneNumber = '0901234567';
    const validStreetAddress = '123 Đường ABC';
    const validWard = 'Phường 1';
    const validDistrict = 'Quận 10';
    const validCity = 'TP. Hồ Chí Minh';

    final testAddress = Address(
      id: '1',
      userId: 'user1',
      recipientName: validRecipientName,
      phoneNumber: validPhoneNumber,
      streetAddress: validStreetAddress,
      ward: validWard,
      district: validDistrict,
      city: validCity,
      isDefault: true,
      createdAt: DateTime.now(),
    );

    test('should add address successfully with valid inputs', () async {
      // Arrange
      when(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: true,
      )).thenAnswer((_) async => testAddress);

      // Act
      final result = await useCase.execute(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: true,
      );

      // Assert
      expect(result, equals(testAddress));
      verify(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: true,
      )).called(1);
    });

    test('should throw ArgumentError when recipient name is empty', () async {
      // Arrange
      const emptyName = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: emptyName,
          phoneNumber: validPhoneNumber,
          streetAddress: validStreetAddress,
          ward: validWard,
          district: validDistrict,
          city: validCity,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.addAddress(
        recipientName: anyNamed('recipientName'),
        phoneNumber: anyNamed('phoneNumber'),
        streetAddress: anyNamed('streetAddress'),
        ward: anyNamed('ward'),
        district: anyNamed('district'),
        city: anyNamed('city'),
        isDefault: anyNamed('isDefault'),
      ));
    });

    test('should throw ArgumentError when phone number is invalid', () async {
      // Arrange
      const invalidPhone = '123';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: validRecipientName,
          phoneNumber: invalidPhone,
          streetAddress: validStreetAddress,
          ward: validWard,
          district: validDistrict,
          city: validCity,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when street address is empty', () async {
      // Arrange
      const emptyStreet = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: validRecipientName,
          phoneNumber: validPhoneNumber,
          streetAddress: emptyStreet,
          ward: validWard,
          district: validDistrict,
          city: validCity,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when ward is empty', () async {
      // Arrange
      const emptyWard = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: validRecipientName,
          phoneNumber: validPhoneNumber,
          streetAddress: validStreetAddress,
          ward: emptyWard,
          district: validDistrict,
          city: validCity,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when district is empty', () async {
      // Arrange
      const emptyDistrict = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: validRecipientName,
          phoneNumber: validPhoneNumber,
          streetAddress: validStreetAddress,
          ward: validWard,
          district: emptyDistrict,
          city: validCity,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when city is empty', () async {
      // Arrange
      const emptyCity = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          recipientName: validRecipientName,
          phoneNumber: validPhoneNumber,
          streetAddress: validStreetAddress,
          ward: validWard,
          district: validDistrict,
          city: emptyCity,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should default isDefault to false if not provided', () async {
      // Arrange
      when(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).thenAnswer((_) async => testAddress.copyWith(isDefault: false));

      // Act
      await useCase.execute(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
      );

      // Assert
      verify(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).called(1);
    });

    test('should trim whitespace from all inputs', () async {
      // Arrange
      when(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).thenAnswer((_) async => testAddress);

      // Act
      final result = await useCase.execute(
        recipientName: '  $validRecipientName  ',
        phoneNumber: '  $validPhoneNumber  ',
        streetAddress: '  $validStreetAddress  ',
        ward: '  $validWard  ',
        district: '  $validDistrict  ',
        city: '  $validCity  ',
      );

      // Assert
      expect(result, equals(testAddress));
      verify(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: validPhoneNumber,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).called(1);
    });

    test('should normalize phone number with country code', () async {
      // Arrange
      const phoneWithCode = '84901234567';
      when(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: '0901234567',
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).thenAnswer((_) async => testAddress);

      // Act
      await useCase.execute(
        recipientName: validRecipientName,
        phoneNumber: phoneWithCode,
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
      );

      // Assert
      verify(mockRepository.addAddress(
        recipientName: validRecipientName,
        phoneNumber: '0901234567',
        streetAddress: validStreetAddress,
        ward: validWard,
        district: validDistrict,
        city: validCity,
        isDefault: false,
      )).called(1);
    });
  });
}
