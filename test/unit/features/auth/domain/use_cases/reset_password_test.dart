import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/reset_password.dart';

import 'reset_password_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late ResetPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetPasswordUseCase(mockRepository);
  });

  group('ResetPasswordUseCase', () {
    const testPhone = '0987654321';
    const testOtp = '123456';
    const testPassword = 'newPassword123';

    test('should call repository with valid credentials', () async {
      // Arrange
      when(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: testPassword,
      )).thenAnswer((_) async => Future.value());

      // Act
      await useCase(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: testPassword,
      );

      // Assert
      verify(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: testPassword,
      )).called(1);
    });

    test('should normalize phone number with 84 prefix', () async {
      // Arrange
      when(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: testPassword,
      )).thenAnswer((_) async => Future.value());

      // Act
      await useCase(
        phoneNumber: '84987654321',
        otpCode: testOtp,
        newPassword: testPassword,
      );

      // Assert
      verify(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: testPassword,
      )).called(1);
    });

    test('should throw ArgumentError when phone number is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: '',
          otpCode: testOtp,
          newPassword: testPassword,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Phone number cannot be empty',
          ),
        ),
      );
    });

    test('should throw ArgumentError for invalid phone format', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: '0187654321',
          otpCode: testOtp,
          newPassword: testPassword,
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

    test('should throw ArgumentError when OTP is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: testPhone,
          otpCode: '',
          newPassword: testPassword,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'OTP code cannot be empty',
          ),
        ),
      );
    });

    test('should throw ArgumentError when OTP is not 6 digits', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: testPhone,
          otpCode: '12345',
          newPassword: testPassword,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'OTP code must be exactly 6 digits',
          ),
        ),
      );
    });

    test('should throw ArgumentError when OTP contains non-digits', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: testPhone,
          otpCode: '12345a',
          newPassword: testPassword,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'OTP code must be exactly 6 digits',
          ),
        ),
      );
    });

    test('should throw ArgumentError when new password is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: testPhone,
          otpCode: testOtp,
          newPassword: '',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'New password cannot be empty',
          ),
        ),
      );
    });

    test('should throw ArgumentError when new password is too short', () async {
      // Act & Assert
      expect(
        () => useCase(
          phoneNumber: testPhone,
          otpCode: testOtp,
          newPassword: 'short',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'New password must be at least 8 characters long',
          ),
        ),
      );
    });

    test('should accept password with exactly 8 characters', () async {
      // Arrange
      const minPassword = '12345678';
      when(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: minPassword,
      )).thenAnswer((_) async => Future.value());

      // Act
      await useCase(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: minPassword,
      );

      // Assert
      verify(mockRepository.resetPassword(
        phoneNumber: testPhone,
        otpCode: testOtp,
        newPassword: minPassword,
      )).called(1);
    });
  });
}
