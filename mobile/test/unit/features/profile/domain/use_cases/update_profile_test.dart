import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/update_profile.dart';
import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/core/models/user.dart';

@GenerateMocks([ProfileRepository])
import 'update_profile_test.mocks.dart';

void main() {
  late UpdateProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    const validFullName = 'Nguyễn Văn B';
    const validEmail = 'newtest@example.com';
    const validAvatarUrl = 'https://example.com/new_avatar.jpg';

    final updatedUser = User(
      id: '1',
      phoneNumber: '0901234567',
      fullName: validFullName,
      email: validEmail,
      passwordHash: 'hashed_password',
      avatarUrl: validAvatarUrl,
      role: UserRole.buyer,
      isVerified: true,
      isSuspended: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should update profile successfully with all fields', () async {
      // Arrange
      when(mockRepository.updateProfile(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      )).thenAnswer((_) async => updatedUser);

      // Act
      final result = await useCase.execute(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      );

      // Assert
      expect(result, equals(updatedUser));
      expect(result.fullName, equals(validFullName));
      expect(result.email, equals(validEmail));
      verify(mockRepository.updateProfile(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      )).called(1);
    });

    test('should update profile with only full name', () async {
      // Arrange
      when(mockRepository.updateProfile(
        fullName: validFullName,
        email: null,
        avatarUrl: null,
      )).thenAnswer((_) async => updatedUser);

      // Act
      final result = await useCase.execute(fullName: validFullName);

      // Assert
      expect(result, equals(updatedUser));
      verify(mockRepository.updateProfile(
        fullName: validFullName,
        email: null,
        avatarUrl: null,
      )).called(1);
    });

    test('should throw ArgumentError when full name is empty', () async {
      // Arrange
      const emptyName = '';

      // Act & Assert
      expect(
        () => useCase.execute(fullName: emptyName),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        email: anyNamed('email'),
        avatarUrl: anyNamed('avatarUrl'),
      ));
    });

    test('should throw ArgumentError when email format is invalid', () async {
      // Arrange
      const invalidEmail = 'invalid-email';

      // Act & Assert
      expect(
        () => useCase.execute(
          fullName: validFullName,
          email: invalidEmail,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        email: anyNamed('email'),
        avatarUrl: anyNamed('avatarUrl'),
      ));
    });

    test('should accept null email to clear it', () async {
      // Arrange
      when(mockRepository.updateProfile(
        fullName: validFullName,
        email: null,
        avatarUrl: null,
      )).thenAnswer((_) async => updatedUser);

      // Act
      final result = await useCase.execute(
        fullName: validFullName,
        email: null,
      );

      // Assert
      expect(result, equals(updatedUser));
    });

    test('should trim whitespace from inputs', () async {
      // Arrange
      when(mockRepository.updateProfile(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      )).thenAnswer((_) async => updatedUser);

      // Act
      final result = await useCase.execute(
        fullName: '  $validFullName  ',
        email: '  $validEmail  ',
        avatarUrl: '  $validAvatarUrl  ',
      );

      // Assert
      expect(result, equals(updatedUser));
      verify(mockRepository.updateProfile(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      )).called(1);
    });

    test('should throw exception when update fails', () async {
      // Arrange
      when(mockRepository.updateProfile(
        fullName: validFullName,
        email: validEmail,
        avatarUrl: validAvatarUrl,
      )).thenThrow(Exception('Update failed'));

      // Act & Assert
      expect(
        () => useCase.execute(
          fullName: validFullName,
          email: validEmail,
          avatarUrl: validAvatarUrl,
        ),
        throwsException,
      );
    });
  });
}
