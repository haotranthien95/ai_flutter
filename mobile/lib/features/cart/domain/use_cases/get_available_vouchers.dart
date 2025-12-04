import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';

/// Use case for getting available vouchers for shop (T147).
class GetAvailableVouchersUseCase {
  /// Creates get available vouchers use case.
  const GetAvailableVouchersUseCase(this._repository);

  final OrderRepository _repository;

  /// Execute get available vouchers.
  ///
  /// Returns vouchers that are active and applicable to the order.
  Future<List<Voucher>> execute({
    required String shopId,
    required double orderSubtotal,
  }) async {
    return _repository.getAvailableVouchers(
      shopId: shopId,
      orderSubtotal: orderSubtotal,
    );
  }
}
