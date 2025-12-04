import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/login.dart';
import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:ai_flutter/core/models/user.dart';

@GenerateMocks([AuthRepository])
import 'login_test.mocks.dart';

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    const validPhoneNumber = '0901234567';
    const validPassword = 'SecurePass123';

    final testUser = User(
      id: '1',
      phoneNumber: validPhoneNumber,
      fullName: 'Nguyễn Văn A',
      email: null,
      passwordHash: 'hashed_password',
      avatarUrl: null,
      role: UserRole.buyer,
      isVerified: true,
      isSuspended: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should login successfully with valid credentials', () async {
      // Arrange
      when(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      )).called(1);
    });

    test('should throw ArgumentError when phone number is empty', () async {
      // Arrange
      const emptyPhone = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: emptyPhone,
          password: validPassword,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.login(
        phoneNumber: anyNamed('phoneNumber'),
        password: anyNamed('password'),
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
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.login(
        phoneNumber: anyNamed('phoneNumber'),
        password: anyNamed('password'),
      ));
    });

    test('should throw exception when credentials are invalid', () async {
      // Arrange
      const wrongPassword = 'WrongPassword';
      when(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: wrongPassword,
      )).thenThrow(Exception('Invalid credentials'));

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: wrongPassword,
        ),
        throwsException,
      );
    });

    test('should throw exception when account is suspended', () async {
      // Arrange
      when(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      )).thenThrow(Exception('Account is suspended'));

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          password: validPassword,
        ),
        throwsException,
      );
    });

    test('should trim whitespace from inputs', () async {
      // Arrange
      when(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: '  $validPhoneNumber  ',
        password: '  $validPassword  ',
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockRepository.login(
        phoneNumber: validPhoneNumber,
        password: validPassword,
      )).called(1);
    });

    test('should normalize phone number with country code', () async {
      // Arrange
      const phoneWithCode = '84901234567';
      when(mockRepository.login(
        phoneNumber: '0901234567',
        password: validPassword,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute(
        phoneNumber: phoneWithCode,
        password: validPassword,
      );

      // Assert
      expect(result, equals(testUser));
    });
  });
}
