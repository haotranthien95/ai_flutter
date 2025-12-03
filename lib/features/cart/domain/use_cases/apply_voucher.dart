import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/features/cart/domain/models/voucher_application_result.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';

/// Use case for applying voucher to order (T146).
class ApplyVoucherUseCase {
  /// Creates apply voucher use case.
  const ApplyVoucherUseCase(this._repository);

  final OrderRepository _repository;

  /// Execute voucher application.
  ///
  /// Validates voucher and calculates discount.
  Future<VoucherApplicationResult> execute({
    required String voucherCode,
    required String shopId,
    required double orderSubtotal,
  }) async {
    // Validate voucher
    final voucher = await _repository.validateVoucher(
      voucherCode: voucherCode,
      shopId: shopId,
      orderSubtotal: orderSubtotal,
    );

    // Check if voucher is valid
    final now = DateTime.now();
    if (now.isBefore(voucher.startDate) || now.isAfter(voucher.endDate)) {
      throw Exception('Voucher has expired');
    }

    if (!voucher.isActive) {
      throw Exception('Voucher is not active');
    }

    if (voucher.usageLimit != null && voucher.usageCount >= voucher.usageLimit!) {
      throw Exception('Voucher usage limit reached');
    }

    if (voucher.minOrderValue != null && orderSubtotal < voucher.minOrderValue!) {
      throw Exception(
        'Order value must be at least ${voucher.minOrderValue} VND',
      );
    }

    // Calculate discount
    double discountAmount;
    if (voucher.type == VoucherType.percentage) {
      discountAmount = orderSubtotal * (voucher.value / 100);
      // Cap at maximum discount amount if specified
      if (voucher.maxDiscount != null &&
          discountAmount > voucher.maxDiscount!) {
        discountAmount = voucher.maxDiscount!;
      }
    } else {
      // Fixed amount discount
      discountAmount = voucher.value;
    }

    final finalAmount = orderSubtotal - discountAmount;

    return VoucherApplicationResult(
      voucher: voucher,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
    );
  }
}
