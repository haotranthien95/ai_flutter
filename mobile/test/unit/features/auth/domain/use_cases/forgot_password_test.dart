import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/forgot_password.dart';

import 'forgot_password_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late ForgotPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ForgotPasswordUseCase(mockRepository);
  });

  group('ForgotPasswordUseCase', () {
    const testPhone = '0987654321';

    test('should call repository with valid phone number', () async {
      // Arrange
      when(mockRepository.forgotPassword(phoneNumber: testPhone))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(phoneNumber: testPhone);

      // Assert
      verify(mockRepository.forgotPassword(phoneNumber: testPhone)).called(1);
    });

    test('should normalize phone number with 84 prefix', () async {
      // Arrange
      when(mockRepository.forgotPassword(phoneNumber: testPhone))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(phoneNumber: '84987654321');

      // Assert
      verify(mockRepository.forgotPassword(phoneNumber: testPhone)).called(1);
    });

    test('should throw ArgumentError when phone number is empty', () async {
      // Act & Assert
      expect(
        () => useCase(phoneNumber: ''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Phone number cannot be empty',
          ),
        ),
      );
    });

    test('should throw ArgumentError for invalid phone format - too short',
        () async {
      // Act & Assert
      expect(
        () => useCase(phoneNumber: '098765432'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid Vietnamese phone number format'),
          ),
        ),
      );
    });

    test('should throw ArgumentError for invalid phone format - wrong prefix',
        () async {
      // Act & Assert
      expect(
        () => useCase(phoneNumber: '0187654321'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid Vietnamese phone number format'),
          ),
        ),
      );
    });

    test('should accept all valid Vietnamese phone prefixes', () async {
      // Arrange
      final validPrefixes = ['03', '05', '07', '08', '09'];
      for (final prefix in validPrefixes) {
        final phone = '$prefix${testPhone.substring(2)}';
        when(mockRepository.forgotPassword(phoneNumber: phone))
            .thenAnswer((_) async => Future.value());
      }

      // Act & Assert
      for (final prefix in validPrefixes) {
        final phone = '$prefix${testPhone.substring(2)}';
        await useCase(phoneNumber: phone);
        verify(mockRepository.forgotPassword(phoneNumber: phone)).called(1);
      }
    });

    test('should throw ArgumentError for non-numeric characters', () async {
      // Act & Assert
      expect(
        () => useCase(phoneNumber: '098765432a'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid Vietnamese phone number format'),
          ),
        ),
      );
    });
  });
}
