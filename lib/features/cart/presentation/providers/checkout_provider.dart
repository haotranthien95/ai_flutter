import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/core/models/address.dart';
import '../../domain/use_cases/place_order.dart';

/// Checkout state model
class CheckoutState {
  const CheckoutState({
    this.selectedAddress,
    this.paymentMethod = PaymentMethod.cod,
    this.notes = '',
    this.isProcessing = false,
    this.error,
  });

  final Address? selectedAddress;
  final PaymentMethod paymentMethod;
  final String notes;
  final bool isProcessing;
  final String? error;

  CheckoutState copyWith({
    Address? selectedAddress,
    PaymentMethod? paymentMethod,
    String? notes,
    bool? isProcessing,
    String? error,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }

  bool get canPlaceOrder => selectedAddress != null && !isProcessing;
}

/// Payment method enum
enum PaymentMethod {
  cod, // Cash on Delivery
  bankTransfer,
  eWallet;

  String get displayName {
    switch (this) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cod:
        return 'Pay when you receive your order';
      case PaymentMethod.bankTransfer:
        return 'Transfer to bank account';
      case PaymentMethod.eWallet:
        return 'Pay with MoMo, ZaloPay, etc.';
    }
  }
}

/// Checkout provider (T153)
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._placeOrderUseCase) : super(const CheckoutState());

  final PlaceOrderUseCase _placeOrderUseCase;

  /// Select delivery address
  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Set payment method
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Set order notes
  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  /// Place order
  Future<String?> placeOrder({
    required List<String> cartItemIds,
    Map<String, String>? shopVouchers,
    String? platformVoucherCode,
  }) async {
    if (!state.canPlaceOrder) {
      return null;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final orderId = await _placeOrderUseCase.execute(
        cartItemIds: cartItemIds,
        addressId: state.selectedAddress!.id,
        paymentMethod: state.paymentMethod.name.toUpperCase(),
        notes: state.notes.isEmpty ? null : state.notes,
        shopVouchers: shopVouchers,
        platformVoucherCode: platformVoucherCode,
      );

      state = state.copyWith(isProcessing: false);
      return orderId;
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  /// Reset checkout state
  void reset() {
    state = const CheckoutState();
  }
}

/// Checkout provider
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final placeOrderUseCase = ref.watch(placeOrderUseCaseProvider);
  return CheckoutNotifier(placeOrderUseCase);
});

/// Use case provider (define in app/providers.dart)
final placeOrderUseCaseProvider = Provider<PlaceOrderUseCase>((ref) {
  throw UnimplementedError('Define in app/providers.dart');
});
