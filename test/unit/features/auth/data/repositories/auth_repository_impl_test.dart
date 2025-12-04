import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ai_flutter/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:ai_flutter/core/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@GenerateMocks([AuthRemoteDataSource, FlutterSecureStorage])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    mockSecureStorage = MockFlutterSecureStorage();
    repository = AuthRepositoryImpl(mockDataSource, mockSecureStorage);
  });

  group('AuthRepositoryImpl - register', () {
    const phoneNumber = '0901234567';
    const password = 'SecurePass123';
    const fullName = 'Nguyễn Văn A';

    final testUser = User(
      id: '1',
      phoneNumber: phoneNumber,
      fullName: fullName,
      email: null,
      passwordHash: 'hashed_password',
      avatarUrl: null,
      role: UserRole.buyer,
      isVerified: false,
      isSuspended: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should register user successfully', () async {
      // Arrange
      when(mockDataSource.register(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.register(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockDataSource.register(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
      )).called(1);
    });

    test('should throw exception when phone already exists', () async {
      // Arrange
      when(mockDataSource.register(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
      )).thenThrow(Exception('Phone number already registered'));

      // Act & Assert
      expect(
        () => repository.register(
          phoneNumber: phoneNumber,
          password: password,
          fullName: fullName,
        ),
        throwsException,
      );
    });
  });

  group('AuthRepositoryImpl - verifyOTP', () {
    const phoneNumber = '0901234567';
    const otpCode = '123456';
    const accessToken = 'mock_access_token';
    const refreshToken = 'mock_refresh_token';

    final tokens = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };

    test('should verify OTP and save tokens', () async {
      // Arrange
      when(mockDataSource.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      )).thenAnswer((_) async => tokens);

      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );

      // Assert
      expect(result, equals(tokens));
      verify(mockSecureStorage.write(key: 'accessToken', value: accessToken))
          .called(1);
      verify(mockSecureStorage.write(key: 'refreshToken', value: refreshToken))
          .called(1);
    });

    test('should throw exception when OTP is invalid', () async {
      // Arrange
      when(mockDataSource.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      )).thenThrow(Exception('Invalid OTP'));

      // Act & Assert
      expect(
        () => repository.verifyOTP(
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        ),
        throwsException,
      );

      verifyNever(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      ));
    });
  });

  group('AuthRepositoryImpl - login', () {
    const phoneNumber = '0901234567';
    const password = 'SecurePass123';
    const accessToken = 'mock_access_token';
    const refreshToken = 'mock_refresh_token';

    final testUser = User(
      id: '1',
      phoneNumber: phoneNumber,
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

    final loginResponse = {
      'user': testUser,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };

    test('should login successfully and save tokens', () async {
      // Arrange
      when(mockDataSource.login(
        phoneNumber: phoneNumber,
        password: password,
      )).thenAnswer((_) async => loginResponse);

      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      // Assert
      expect(result, equals(testUser));
      verify(mockSecureStorage.write(key: 'accessToken', value: accessToken))
          .called(1);
      verify(mockSecureStorage.write(key: 'refreshToken', value: refreshToken))
          .called(1);
    });

    test('should throw exception when credentials are invalid', () async {
      // Arrange
      when(mockDataSource.login(
        phoneNumber: phoneNumber,
        password: password,
      )).thenThrow(Exception('Invalid credentials'));

      // Act & Assert
      expect(
        () => repository.login(
          phoneNumber: phoneNumber,
          password: password,
        ),
        throwsException,
      );
    });
  });

  group('AuthRepositoryImpl - logout', () {
    test('should logout successfully and clear tokens', () async {
      // Arrange
      when(mockDataSource.logout()).thenAnswer((_) async => Future.value());
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async => Future.value());

      // Act
      await repository.logout();

      // Assert
      verify(mockDataSource.logout()).called(1);
      verify(mockSecureStorage.delete(key: 'accessToken')).called(1);
      verify(mockSecureStorage.delete(key: 'refreshToken')).called(1);
    });

    test('should clear tokens even if remote logout fails', () async {
      // Arrange
      when(mockDataSource.logout()).thenThrow(Exception('Network error'));
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async => Future.value());

      // Act & Assert - should not throw
      await repository.logout();

      // Assert - tokens still cleared
      verify(mockSecureStorage.delete(key: 'accessToken')).called(1);
      verify(mockSecureStorage.delete(key: 'refreshToken')).called(1);
    });
  });

  group('AuthRepositoryImpl - refreshToken', () {
    const oldRefreshToken = 'old_refresh_token';
    const newAccessToken = 'new_access_token';
    const newRefreshToken = 'new_refresh_token';

    final tokens = {
      'accessToken': newAccessToken,
      'refreshToken': newRefreshToken,
    };

    test('should refresh token and save new tokens', () async {
      // Arrange
      when(mockDataSource.refreshToken(refreshToken: oldRefreshToken))
          .thenAnswer((_) async => tokens);

      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async => Future.value());

      // Act
      final result =
          await repository.refreshToken(refreshToken: oldRefreshToken);

      // Assert
      expect(result, equals(tokens));
      verify(mockSecureStorage.write(key: 'accessToken', value: newAccessToken))
          .called(1);
      verify(mockSecureStorage.write(
              key: 'refreshToken', value: newRefreshToken))
          .called(1);
    });
  });

  group('AuthRepositoryImpl - getCurrentUser', () {
    test('should return null when no access token stored', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'accessToken'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('AuthRepositoryImpl - isAuthenticated', () {
    test('should return true when access token exists', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'accessToken'))
          .thenAnswer((_) async => 'some_token');

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isTrue);
    });

    test('should return false when no access token', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'accessToken'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });
  });
}
