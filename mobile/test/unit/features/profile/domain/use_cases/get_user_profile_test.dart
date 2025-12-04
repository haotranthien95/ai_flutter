import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/get_user_profile.dart';
import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/core/models/user.dart';

@GenerateMocks([ProfileRepository])
import 'get_user_profile_test.mocks.dart';

void main() {
  late GetUserProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetUserProfileUseCase(mockRepository);
  });

  group('GetUserProfileUseCase', () {
    final testUser = User(
      id: '1',
      phoneNumber: '0901234567',
      fullName: 'Nguyễn Văn A',
      email: 'test@example.com',
      passwordHash: 'hashed_password',
      avatarUrl: 'https://example.com/avatar.jpg',
      role: UserRole.buyer,
      isVerified: true,
      isSuspended: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should get user profile successfully', () async {
      // Arrange
      when(mockRepository.getUserProfile()).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(testUser));
      expect(result.fullName, equals('Nguyễn Văn A'));
      expect(result.email, equals('test@example.com'));
      verify(mockRepository.getUserProfile()).called(1);
    });

    test('should throw exception when user not found', () async {
      // Arrange
      when(mockRepository.getUserProfile())
          .thenThrow(Exception('User not found'));

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsException,
      );
    });

    test('should throw exception when unauthorized', () async {
      // Arrange
      when(mockRepository.getUserProfile())
          .thenThrow(Exception('Unauthorized'));

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsException,
      );
    });
  });
}
