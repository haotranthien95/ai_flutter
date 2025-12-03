import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ai_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:ai_flutter/features/profile/domain/use_cases/delete_address.dart';

import 'delete_address_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late DeleteAddressUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = DeleteAddressUseCase(mockRepository);
  });

  group('DeleteAddressUseCase', () {
    const testAddressId = 'addr_123';

    test('should call repository with valid address ID', () async {
      // Arrange
      when(mockRepository.deleteAddress(testAddressId))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(testAddressId);

      // Assert
      verify(mockRepository.deleteAddress(testAddressId)).called(1);
    });

    test('should throw ArgumentError when addressId is empty', () async {
      // Act & Assert
      expect(
        () => useCase(''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Address ID cannot be empty',
          ),
        ),
      );
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.deleteAddress(testAddressId))
          .thenThrow(Exception('Address not found'));

      // Act & Assert
      expect(
        () => useCase(testAddressId),
        throwsException,
      );
    });
  });
}
