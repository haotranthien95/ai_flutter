import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/verify_otp.dart';
import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
import 'verify_otp_test.mocks.dart';

void main() {
  late VerifyOTPUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyOTPUseCase(mockRepository);
  });

  group('VerifyOTPUseCase', () {
    const validPhoneNumber = '0901234567';
    const validOTP = '123456';

    final testTokens = {
      'accessToken': 'mock_access_token',
      'refreshToken': 'mock_refresh_token',
    };

    test('should verify OTP successfully with valid code', () async {
      // Arrange
      when(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: validOTP,
      )).thenAnswer((_) async => testTokens);

      // Act
      final result = await useCase.execute(
        phoneNumber: validPhoneNumber,
        otpCode: validOTP,
      );

      // Assert
      expect(result, equals(testTokens));
      expect(result['accessToken'], equals('mock_access_token'));
      expect(result['refreshToken'], equals('mock_refresh_token'));
      verify(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: validOTP,
      )).called(1);
    });

    test('should throw ArgumentError when phone number is empty', () async {
      // Arrange
      const emptyPhone = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: emptyPhone,
          otpCode: validOTP,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.verifyOTP(
        phoneNumber: anyNamed('phoneNumber'),
        otpCode: anyNamed('otpCode'),
      ));
    });

    test('should throw ArgumentError when OTP code is empty', () async {
      // Arrange
      const emptyOTP = '';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          otpCode: emptyOTP,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.verifyOTP(
        phoneNumber: anyNamed('phoneNumber'),
        otpCode: anyNamed('otpCode'),
      ));
    });

    test('should throw ArgumentError when OTP is not 6 digits', () async {
      // Arrange
      const invalidOTP = '12345'; // Too short

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          otpCode: invalidOTP,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when OTP contains non-digits', () async {
      // Arrange
      const invalidOTP = '12a456';

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          otpCode: invalidOTP,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw exception when OTP is invalid', () async {
      // Arrange
      const invalidOTP = '000000';
      when(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: invalidOTP,
      )).thenThrow(Exception('Invalid OTP code'));

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          otpCode: invalidOTP,
        ),
        throwsException,
      );
    });

    test('should throw exception when OTP is expired', () async {
      // Arrange
      const expiredOTP = '999999';
      when(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: expiredOTP,
      )).thenThrow(Exception('OTP code has expired'));

      // Act & Assert
      expect(
        () => useCase.execute(
          phoneNumber: validPhoneNumber,
          otpCode: expiredOTP,
        ),
        throwsException,
      );
    });

    test('should trim whitespace from inputs', () async {
      // Arrange
      when(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: validOTP,
      )).thenAnswer((_) async => testTokens);

      // Act
      final result = await useCase.execute(
        phoneNumber: '  $validPhoneNumber  ',
        otpCode: '  $validOTP  ',
      );

      // Assert
      expect(result, equals(testTokens));
      verify(mockRepository.verifyOTP(
        phoneNumber: validPhoneNumber,
        otpCode: validOTP,
      )).called(1);
    });
  });
}
