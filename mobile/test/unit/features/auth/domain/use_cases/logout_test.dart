import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ai_flutter/features/auth/domain/use_cases/logout.dart';
import 'package:ai_flutter/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
import 'logout_test.mocks.dart';

void main() {
  late LogoutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase', () {
    test('should logout successfully', () async {
      // Arrange
      when(mockRepository.logout()).thenAnswer((_) async => Future.value());

      // Act
      await useCase.execute();

      // Assert
      verify(mockRepository.logout()).called(1);
    });

    test('should handle logout error gracefully', () async {
      // Arrange
      when(mockRepository.logout())
          .thenThrow(Exception('Failed to clear tokens'));

      // Act & Assert
      expect(
        () => useCase.execute(),
        throwsException,
      );
    });
  });
}
