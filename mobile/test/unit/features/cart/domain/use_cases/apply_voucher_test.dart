import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/apply_voucher.dart';

import 'apply_voucher_test.mocks.dart';

@GenerateMocks([OrderRepository])
void main() {
  late ApplyVoucherUseCase useCase;
  late MockOrderRepository mockRepository;

  setUp(() {
    mockRepository = MockOrderRepository();
    useCase = ApplyVoucherUseCase(mockRepository);
  });

  group('ApplyVoucherUseCase (T126)', () {
    const testVoucherCode = 'SAVE20';
    const testShopId = 'shop-1';
    const testOrderSubtotal = 250000.0;

    final testVoucher = Voucher(
      id: 'voucher-1',
      code: testVoucherCode,
      shopId: testShopId,
      title: 'Save 20%',
      description: 'Get 20% off your order',
      type: VoucherType.percentage,
      value: 20,
      minOrderValue: 100000,
      maxDiscount: 50000,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      usageLimit: 100,
      usageCount: 10,
      isActive: true,
    );

    test('should apply valid percentage voucher successfully', () async {
      // Arrange
      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenAnswer((_) async => testVoucher);

      // Act
      final result = await useCase.execute(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      );

      // Assert
      expect(result.discountAmount, 50000); // 20% of 250000 = 50000
      expect(result.finalAmount, 200000); // 250000 - 50000
      expect(result.voucher, testVoucher);
      verify(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).called(1);
    });

    test('should apply fixed amount voucher successfully', () async {
      // Arrange
      final fixedVoucher = testVoucher.copyWith(
        type: VoucherType.fixedAmount,
        value: 30000,
      );

      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenAnswer((_) async => fixedVoucher);

      // Act
      final result = await useCase.execute(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      );

      // Assert
      expect(result.discountAmount, 30000);
      expect(result.finalAmount, 220000); // 250000 - 30000
    });

    test('should cap discount at maximum discount amount for percentage',
        () async {
      // Arrange
      const largeSubtotal = 1000000.0; // 1M VND
      final voucherWith50kCap = testVoucher.copyWith(
        maxDiscount: 50000,
      );

      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: largeSubtotal,
      )).thenAnswer((_) async => voucherWith50kCap);

      // Act
      final result = await useCase.execute(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: largeSubtotal,
      );

      // Assert
      // 20% of 1M = 200k, but capped at 50k
      expect(result.discountAmount, 50000);
      expect(result.finalAmount, 950000);
    });

    test('should throw exception for expired voucher', () async {
      // Arrange
      final expiredVoucher = testVoucher.copyWith(
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenAnswer((_) async => expiredVoucher);

      // Act & Assert
      expect(
        () => useCase.execute(
          voucherCode: testVoucherCode,
          shopId: testShopId,
          orderSubtotal: testOrderSubtotal,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when order below minimum value', () async {
      // Arrange
      const lowSubtotal = 50000.0;
      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: lowSubtotal,
      )).thenThrow(Exception('Order value below minimum'));

      // Act & Assert
      expect(
        () => useCase.execute(
          voucherCode: testVoucherCode,
          shopId: testShopId,
          orderSubtotal: lowSubtotal,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when usage limit reached', () async {
      // Arrange
      final maxedVoucher = testVoucher.copyWith(
        usageLimit: 10,
        usageCount: 10,
      );

      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenAnswer((_) async => maxedVoucher);

      // Act & Assert
      expect(
        () => useCase.execute(
          voucherCode: testVoucherCode,
          shopId: testShopId,
          orderSubtotal: testOrderSubtotal,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for inactive voucher', () async {
      // Arrange
      final inactiveVoucher = testVoucher.copyWith(isActive: false);

      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenAnswer((_) async => inactiveVoucher);

      // Act & Assert
      expect(
        () => useCase.execute(
          voucherCode: testVoucherCode,
          shopId: testShopId,
          orderSubtotal: testOrderSubtotal,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle repository errors', () async {
      // Arrange
      when(mockRepository.validateVoucher(
        voucherCode: testVoucherCode,
        shopId: testShopId,
        orderSubtotal: testOrderSubtotal,
      )).thenThrow(Exception('Voucher not found'));

      // Act & Assert
      expect(
        () => useCase.execute(
          voucherCode: testVoucherCode,
          shopId: testShopId,
          orderSubtotal: testOrderSubtotal,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
