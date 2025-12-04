import 'package:ai_flutter/core/models/voucher.dart';

/// Result of applying a voucher to an order.
class VoucherApplicationResult {
  /// Creates a voucher application result.
  const VoucherApplicationResult({
    required this.voucher,
    required this.discountAmount,
    required this.finalAmount,
  });

  /// Applied voucher.
  final Voucher voucher;

  /// Calculated discount amount in VND.
  final double discountAmount;

  /// Final amount after discount.
  final double finalAmount;
}
