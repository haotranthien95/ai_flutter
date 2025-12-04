import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/features/cart/data/data_sources/order_remote_data_source.dart';
import 'package:ai_flutter/features/cart/data/repositories/order_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'order_repository_impl_test.mocks.dart';

@GenerateMocks([OrderRemoteDataSource])
void main() {
  late OrderRepositoryImpl repository;
  late MockOrderRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockOrderRemoteDataSource();
    repository = OrderRepositoryImpl(mockDataSource);
  });

  group('OrderRepositoryImpl (T127)', () {
    group('createOrder', () {
      test('should create order successfully', () async {
        // Arrange
        const userId = 'user123';
        final items = [
          CartItem(
            id: 'cart1',
            userId: userId,
            productId: 'prod1',
            variantId: 'var1',
            quantity: 2,
            addedAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        const addressId = 'addr1';
        const paymentMethod = 'COD';

        final expectedOrders = [
          Order(
            id: 'order1',
            orderNumber: 'ORD-001',
            buyerId: userId,
            shopId: 'shop1',
            addressId: addressId,
            shippingAddress: const {},
            status: OrderStatus.pending,
            paymentMethod: PaymentMethod.cod,
            paymentStatus: PaymentStatus.pending,
            subtotal: 100.0,
            shippingFee: 10.0,
            discount: 0.0,
            total: 110.0,
            currency: 'VND',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];

        when(mockDataSource.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
          voucherCode: null,
          notes: null,
        )).thenAnswer((_) async => expectedOrders);

        // Act
        final result = await repository.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result, expectedOrders);
        verify(mockDataSource.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
          voucherCode: null,
          notes: null,
        )).called(1);
      });

      test('should create order with voucher code', () async {
        // Arrange
        const userId = 'user123';
        final items = [
          CartItem(
            id: 'cart1',
            userId: userId,
            productId: 'prod1',
            variantId: 'var1',
            quantity: 2,
            addedAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        const addressId = 'addr1';
        const paymentMethod = 'COD';
        const voucherCode = 'SAVE20';

        final expectedOrders = [
          Order(
            id: 'order1',
            orderNumber: 'ORD-001',
            buyerId: userId,
            shopId: 'shop1',
            addressId: addressId,
            shippingAddress: const {},
            status: OrderStatus.pending,
            paymentMethod: PaymentMethod.cod,
            paymentStatus: PaymentStatus.pending,
            subtotal: 100.0,
            shippingFee: 10.0,
            discount: 20.0,
            total: 90.0,
            currency: 'VND',
            voucherCode: voucherCode,
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];

        when(mockDataSource.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
          voucherCode: voucherCode,
          notes: null,
        )).thenAnswer((_) async => expectedOrders);

        // Act
        final result = await repository.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
          voucherCode: voucherCode,
        );

        // Assert
        expect(result, expectedOrders);
        expect(result.first.discount, 20.0);
        expect(result.first.voucherCode, voucherCode);
      });

      test('should throw exception on create order failure', () async {
        // Arrange
        const userId = 'user123';
        final items = [
          CartItem(
            id: 'cart1',
            userId: userId,
            productId: 'prod1',
            variantId: 'var1',
            quantity: 2,
            addedAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        const addressId = 'addr1';
        const paymentMethod = 'COD';

        when(mockDataSource.createOrder(
          userId: userId,
          items: items,
          addressId: addressId,
          paymentMethod: paymentMethod,
          voucherCode: null,
          notes: null,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.createOrder(
            userId: userId,
            items: items,
            addressId: addressId,
            paymentMethod: paymentMethod,
          ),
          throwsException,
        );
      });
    });

    group('getOrders', () {
      test('should get orders for user', () async {
        // Arrange
        const userId = 'user123';
        final expectedOrders = [
          Order(
            id: 'order1',
            orderNumber: 'ORD-001',
            buyerId: userId,
            shopId: 'shop1',
            addressId: 'addr1',
            shippingAddress: const {},
            status: OrderStatus.pending,
            paymentMethod: PaymentMethod.cod,
            paymentStatus: PaymentStatus.pending,
            subtotal: 100.0,
            shippingFee: 10.0,
            discount: 0.0,
            total: 110.0,
            currency: 'VND',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];

        when(mockDataSource.getOrders(
          userId: userId,
          status: null,
          limit: null,
          cursor: null,
        )).thenAnswer((_) async => expectedOrders);

        // Act
        final result = await repository.getOrders(userId: userId);

        // Assert
        expect(result, expectedOrders);
        verify(mockDataSource.getOrders(
          userId: userId,
          status: null,
          limit: null,
          cursor: null,
        )).called(1);
      });

      test('should get orders with status filter', () async {
        // Arrange
        const userId = 'user123';
        const status = 'completed';
        final expectedOrders = [
          Order(
            id: 'order1',
            orderNumber: 'ORD-001',
            buyerId: userId,
            shopId: 'shop1',
            addressId: 'addr1',
            shippingAddress: const {},
            status: OrderStatus.completed,
            paymentMethod: PaymentMethod.cod,
            paymentStatus: PaymentStatus.paid,
            subtotal: 100.0,
            shippingFee: 10.0,
            discount: 0.0,
            total: 110.0,
            currency: 'VND',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];

        when(mockDataSource.getOrders(
          userId: userId,
          status: status,
          limit: null,
          cursor: null,
        )).thenAnswer((_) async => expectedOrders);

        // Act
        final result = await repository.getOrders(
          userId: userId,
          status: status,
        );

        // Assert
        expect(result, expectedOrders);
        expect(result.first.status, OrderStatus.completed);
      });

      test('should throw exception on get orders failure', () async {
        // Arrange
        const userId = 'user123';

        when(mockDataSource.getOrders(
          userId: userId,
          status: null,
          limit: null,
          cursor: null,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getOrders(userId: userId),
          throwsException,
        );
      });
    });

    group('getOrderDetail', () {
      test('should get order detail by id', () async {
        // Arrange
        const orderId = 'order123';
        final expectedOrder = Order(
          id: orderId,
          orderNumber: 'ORD-001',
          buyerId: 'user123',
          shopId: 'shop1',
          addressId: 'addr1',
          shippingAddress: const {},
          status: OrderStatus.pending,
          paymentMethod: PaymentMethod.cod,
          paymentStatus: PaymentStatus.pending,
          subtotal: 100.0,
          shippingFee: 10.0,
          discount: 0.0,
          total: 110.0,
          currency: 'VND',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        when(mockDataSource.getOrderDetail(orderId))
            .thenAnswer((_) async => expectedOrder);

        // Act
        final result = await repository.getOrderDetail(orderId);

        // Assert
        expect(result, expectedOrder);
        expect(result.id, orderId);
        verify(mockDataSource.getOrderDetail(orderId)).called(1);
      });

      test('should throw exception on get order detail failure', () async {
        // Arrange
        const orderId = 'order123';

        when(mockDataSource.getOrderDetail(orderId))
            .thenThrow(Exception('Order not found'));

        // Act & Assert
        expect(
          () => repository.getOrderDetail(orderId),
          throwsException,
        );
      });
    });

    group('cancelOrder', () {
      test('should cancel order successfully', () async {
        // Arrange
        const orderId = 'order123';
        const reason = 'Changed my mind';
        final expectedOrder = Order(
          id: orderId,
          orderNumber: 'ORD-001',
          buyerId: 'user123',
          shopId: 'shop1',
          addressId: 'addr1',
          shippingAddress: const {},
          status: OrderStatus.cancelled,
          paymentMethod: PaymentMethod.cod,
          paymentStatus: PaymentStatus.pending,
          subtotal: 100.0,
          shippingFee: 10.0,
          discount: 0.0,
          total: 110.0,
          currency: 'VND',
          cancellationReason: reason,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        when(mockDataSource.cancelOrder(
          orderId: orderId,
          reason: reason,
          notes: null,
        )).thenAnswer((_) async => expectedOrder);

        // Act
        final result = await repository.cancelOrder(
          orderId: orderId,
          reason: reason,
        );

        // Assert
        expect(result, expectedOrder);
        expect(result.status, OrderStatus.cancelled);
        expect(result.cancellationReason, reason);
        verify(mockDataSource.cancelOrder(
          orderId: orderId,
          reason: reason,
          notes: null,
        )).called(1);
      });

      test('should throw exception on cancel order failure', () async {
        // Arrange
        const orderId = 'order123';
        const reason = 'Changed my mind';

        when(mockDataSource.cancelOrder(
          orderId: orderId,
          reason: reason,
          notes: null,
        )).thenThrow(Exception('Cannot cancel order'));

        // Act & Assert
        expect(
          () => repository.cancelOrder(
            orderId: orderId,
            reason: reason,
          ),
          throwsException,
        );
      });
    });

    group('validateVoucher', () {
      test('should validate voucher successfully', () async {
        // Arrange
        const voucherCode = 'SAVE20';
        const shopId = 'shop1';
        const orderSubtotal = 100.0;
        final expectedVoucher = Voucher(
          id: 'voucher1',
          shopId: shopId,
          code: voucherCode,
          title: 'Save 20%',
          type: VoucherType.percentage,
          value: 20.0,
          minOrderValue: 50.0,
          usageCount: 0,
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
          isActive: true,
        );

        when(mockDataSource.validateVoucher(
          voucherCode: voucherCode,
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).thenAnswer((_) async => expectedVoucher);

        // Act
        final result = await repository.validateVoucher(
          voucherCode: voucherCode,
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        );

        // Assert
        expect(result, expectedVoucher);
        expect(result.code, voucherCode);
        verify(mockDataSource.validateVoucher(
          voucherCode: voucherCode,
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).called(1);
      });

      test('should throw exception on invalid voucher', () async {
        // Arrange
        const voucherCode = 'INVALID';
        const shopId = 'shop1';
        const orderSubtotal = 100.0;

        when(mockDataSource.validateVoucher(
          voucherCode: voucherCode,
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).thenThrow(Exception('Voucher not found'));

        // Act & Assert
        expect(
          () => repository.validateVoucher(
            voucherCode: voucherCode,
            shopId: shopId,
            orderSubtotal: orderSubtotal,
          ),
          throwsException,
        );
      });
    });

    group('getAvailableVouchers', () {
      test('should get available vouchers for shop', () async {
        // Arrange
        const shopId = 'shop1';
        const orderSubtotal = 100.0;
        final expectedVouchers = [
          Voucher(
            id: 'voucher1',
            shopId: shopId,
            code: 'SAVE20',
            title: 'Save 20%',
            type: VoucherType.percentage,
            value: 20.0,
            minOrderValue: 50.0,
            usageCount: 0,
            startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 12, 31),
            isActive: true,
          ),
          Voucher(
            id: 'voucher2',
            shopId: shopId,
            code: 'SAVE10',
            title: 'Save 10k',
            type: VoucherType.fixedAmount,
            value: 10.0,
            minOrderValue: 30.0,
            usageCount: 0,
            startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 12, 31),
            isActive: true,
          ),
        ];

        when(mockDataSource.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).thenAnswer((_) async => expectedVouchers);

        // Act
        final result = await repository.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        );

        // Assert
        expect(result, expectedVouchers);
        expect(result.length, 2);
        verify(mockDataSource.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).called(1);
      });

      test('should return empty list when no vouchers available', () async {
        // Arrange
        const shopId = 'shop1';
        const orderSubtotal = 10.0;
        final expectedVouchers = <Voucher>[];

        when(mockDataSource.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).thenAnswer((_) async => expectedVouchers);

        // Act
        final result = await repository.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should throw exception on get available vouchers failure',
          () async {
        // Arrange
        const shopId = 'shop1';
        const orderSubtotal = 100.0;

        when(mockDataSource.getAvailableVouchers(
          shopId: shopId,
          orderSubtotal: orderSubtotal,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getAvailableVouchers(
            shopId: shopId,
            orderSubtotal: orderSubtotal,
          ),
          throwsException,
        );
      });
    });
  });
}
