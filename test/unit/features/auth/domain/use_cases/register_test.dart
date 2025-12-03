import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/register.dart';
import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:ai_flutter/core/models/user.dart';

@GenerateMocks([AuthRepository])
import 'register_test.mocks.dart';

void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  group('RegisterUseCase', () {
    const validPhoneNumber = '0901234567';
    const validPassword = 'SecurePass123';
    const validFullName = 'Nguyễn Văn A';

    final testUser = User(
      id: '1',
      phoneNumber: validPhoneNumber,
      fullName: validFullName,
      email: null,
      passwordHash: 'hashed_password',
      avatarUrl: null,
      role: UserRole.buyer,
      isVerified: false,
      isSuspended: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should register user successfully with valid inputs', () async {
      // Arrange
      when(mockRepository.register(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockRepository.register(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      )).called(1);
    });

    test('should throw ArgumentError when phone number is invalid', () async {
      // Arrange
      const invalidPhone = '123'; // Too short

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: invalidPhone,
          password: validPassword,
          fullName: validFullName,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.register(
        phoneNumber: anyNamed('phoneNumber'),
        password: anyNamed('password'),
        fullName: anyNamed('fullName'),
      ));
    });

    test('should throw ArgumentError when phone number format is invalid',
        () async {
      // Arrange
      const invalidPhone = '1234567890'; // Doesn't start with 0

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: invalidPhone,
          password: validPassword,
          fullName: validFullName,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when password is too short', () async {
      // Arrange
      const weakPassword = '1234567'; // Less than 8 characters

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: weakPassword,
          fullName: validFullName,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.register(
        phoneNumber: anyNamed('phoneNumber'),
        password: anyNamed('password'),
        fullName: anyNamed('fullName'),
      ));
    });

    test('should throw ArgumentError when password is empty', () async {
      // Arrange
      const emptyPassword = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: emptyPassword,
          fullName: validFullName,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when fullName is empty', () async {
      // Arrange
      const emptyName = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: validPassword,
          fullName: emptyName,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.register(
        phoneNumber: anyNamed('phoneNumber'),
        password: anyNamed('password'),
        fullName: anyNamed('fullName'),
      ));
    });

    test('should throw exception when phone number already exists', () async {
      // Arrange
      when(mockRepository.register(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      )).thenThrow(Exception('Phone number already registered'));

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: validPassword,
          fullName: validFullName,
        ),
        throwsException,
      );
    });

    test('should accept Vietnamese phone number with country code', () async {
      // Arrange
      const phoneWithCode = '84901234567';
      when(mockRepository.register(
        phoneNumber: '0901234567', // Should normalize to local format
        password: validPassword,
        fullName: validFullName,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: phoneWithCode,
        password: validPassword,
        fullName: validFullName,
      );

      // Assert
      expect(result, equals(testUser));
    });

    test('should trim whitespace from inputs', () async {
      // Arrange
      when(mockRepository.register(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: '  $validPhoneNumber  ',
        password: '  $validPassword  ',
        fullName: '  $validFullName  ',
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockRepository.register(
        phoneNumber: validPhoneNumber,
        password: validPassword,
        fullName: validFullName,
      )).called(1);
    });
  });
}
