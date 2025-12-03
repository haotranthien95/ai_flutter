import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/checkout.dart';

import 'checkout_test.mocks.dart';

@GenerateMocks([CartRepository, OrderRepository])
void main() {
  late CheckoutUseCase useCase;
  late MockCartRepository mockCartRepository;
  late MockOrderRepository mockOrderRepository;

  setUp(() {
    mockCartRepository = MockCartRepository();
    mockOrderRepository = MockOrderRepository();
    useCase = CheckoutUseCase(mockCartRepository, mockOrderRepository);
  });

  group('CheckoutUseCase (T125)', () {
    const testUserId = 'user-789';
    const testAddressId = 'address-123';
    const testPaymentMethod = 'COD';

    final testCartItems = <CartItem>[
      CartItem(
        id: 'cart-item-1',
        userId: testUserId,
        productId: 'product-1',
        variantId: null,
        quantity: 2,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CartItem(
        id: 'cart-item-2',
        userId: testUserId,
        productId: 'product-2',
        variantId: 'variant-1',
        quantity: 1,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should create order successfully from cart', () async {
      // Arrange
      final expectedOrder = Order(
        id: 'order-123',
        userId: testUserId,
        shopId: 'shop-1',
        orderNumber: 'ORD-20251203-001',
        status: OrderStatus.pending,
        items: <String>[],
        subtotal: 250000,
        shippingFee: 30000,
        discount: 0,
        total: 280000,
        paymentMethod: testPaymentMethod,
        paymentStatus: PaymentStatus.pending,
        shippingAddressId: testAddressId,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => testCartItems);
      when(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: null,
        notes: null,
      )).thenAnswer((_) async => <Order>[expectedOrder]);
      when(mockCartRepository.clearCart(testUserId))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
      );

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.id, expectedOrder.id);
      verify(mockCartRepository.getCart(testUserId)).called(1);
      verify(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: null,
        notes: null,
      )).called(1);
      verify(mockCartRepository.clearCart(testUserId)).called(1);
    });

    test('should apply voucher code during checkout', () async {
      // Arrange
      const voucherCode = 'SAVE20';
      final expectedOrder = Order(
        id: 'order-123',
        userId: testUserId,
        shopId: 'shop-1',
        orderNumber: 'ORD-20251203-001',
        status: OrderStatus.pending,
        items: <String>[],
        subtotal: 250000,
        shippingFee: 30000,
        discount: 50000,
        total: 230000,
        paymentMethod: testPaymentMethod,
        paymentStatus: PaymentStatus.pending,
        shippingAddressId: testAddressId,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => testCartItems);
      when(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: voucherCode,
        notes: null,
      )).thenAnswer((_) async => <Order>[expectedOrder]);
      when(mockCartRepository.clearCart(testUserId))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: voucherCode,
      );

      // Assert
      expect(result.first.discount, 50000);
      verify(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: voucherCode,
        notes: null,
      )).called(1);
    });

    test('should throw exception when cart is empty', () async {
      // Arrange
      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => <CartItem>[]);

      // Act & Assert
      expect(
        () => useCase.execute(
          userId: testUserId,
          addressId: testAddressId,
          paymentMethod: testPaymentMethod,
        ),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockOrderRepository.createOrder(
        userId: anyNamed('userId'),
        items: anyNamed('items'),
        addressId: anyNamed('addressId'),
        paymentMethod: anyNamed('paymentMethod'),
        voucherCode: anyNamed('voucherCode'),
        notes: anyNamed('notes'),
      ));
    });

    test('should clear cart after successful order creation', () async {
      // Arrange
      final expectedOrder = Order(
        id: 'order-123',
        userId: testUserId,
        shopId: 'shop-1',
        orderNumber: 'ORD-20251203-001',
        status: OrderStatus.pending,
        items: <String>[],
        subtotal: 250000,
        shippingFee: 30000,
        discount: 0,
        total: 280000,
        paymentMethod: testPaymentMethod,
        paymentStatus: PaymentStatus.pending,
        shippingAddressId: testAddressId,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => testCartItems);
      when(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: null,
        notes: null,
      )).thenAnswer((_) async => <Order>[expectedOrder]);
      when(mockCartRepository.clearCart(testUserId))
          .thenAnswer((_) async => {});

      // Act
      await useCase.execute(
        userId: testUserId,
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
      );

      // Assert
      verify(mockCartRepository.clearCart(testUserId)).called(1);
    });

    test('should not clear cart if order creation fails', () async {
      // Arrange
      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => testCartItems);
      when(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: null,
        notes: null,
      )).thenThrow(Exception('Order creation failed'));

      // Act & Assert
      expect(
        () => useCase.execute(
          userId: testUserId,
          addressId: testAddressId,
          paymentMethod: testPaymentMethod,
        ),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockCartRepository.clearCart(any));
    });

    test('should include notes in order', () async {
      // Arrange
      const notes = 'Please deliver before 5pm';
      final expectedOrder = Order(
        id: 'order-123',
        userId: testUserId,
        shopId: 'shop-1',
        orderNumber: 'ORD-20251203-001',
        status: OrderStatus.pending,
        items: <String>[],
        subtotal: 250000,
        shippingFee: 30000,
        discount: 0,
        total: 280000,
        paymentMethod: testPaymentMethod,
        paymentStatus: PaymentStatus.pending,
        shippingAddressId: testAddressId,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockCartRepository.getCart(testUserId))
          .thenAnswer((_) async => testCartItems);
      when(mockOrderRepository.createOrder(
        userId: testUserId,
        items: anyNamed('items'),
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        voucherCode: null,
        notes: notes,
      )).thenAnswer((_) async => <Order>[expectedOrder]);
      when(mockCartRepository.clearCart(testUserId))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        userId: testUserId,
        addressId: testAddressId,
        paymentMethod: testPaymentMethod,
        notes: notes,
      );

      // Assert
      expect(result.first.notes, notes);
    });
  });
}
