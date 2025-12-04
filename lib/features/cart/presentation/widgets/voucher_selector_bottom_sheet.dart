import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_flutter/core/models/voucher.dart';

class VoucherSelectorBottomSheet extends ConsumerStatefulWidget {
  final String? shopId; // null for platform vouchers
  final double orderTotal;

  const VoucherSelectorBottomSheet({
    super.key,
    this.shopId,
    required this.orderTotal,
  });

  @override
  ConsumerState<VoucherSelectorBottomSheet> createState() =>
      _VoucherSelectorBottomSheetState();
}

class _VoucherSelectorBottomSheetState
    extends ConsumerState<VoucherSelectorBottomSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isShopVoucher = widget.shopId != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isShopVoucher ? 'Shop Vouchers' : 'Platform Vouchers',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Manual code input
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter voucher code',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              hintText: 'VOUCHER CODE',
                              errorText: _errorMessage,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _applyManualCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Available vouchers list
              Expanded(
                child: FutureBuilder<List<Voucher>>(
                  future: _loadAvailableVouchers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 16),
                            Text('Error loading vouchers'),
                            TextButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final vouchers = snapshot.data ?? [];
                    if (vouchers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No vouchers available',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        return _buildVoucherCard(voucher);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final theme = Theme.of(context);
    final minOrder = voucher.minOrderValue ?? 0;
    final isEligible = widget.orderTotal >= minOrder;
    final discount = voucher.calculateDiscount(widget.orderTotal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isEligible
            ? () {
                _applyVoucher(voucher);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: isEligible
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voucher.code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEligible
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    voucher.type == VoucherType.percentage
                        ? '${voucher.value}% OFF'
                        : '\$${voucher.value.toStringAsFixed(2)} OFF',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEligible
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (voucher.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  voucher.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Min. order: \$${minOrder.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (voucher.maxDiscount != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Max discount: \$${voucher.maxDiscount!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Valid until: ${_formatDate(voucher.endDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isEligible) ...[
                const SizedBox(height: 8),
                Text(
                  'Add \$${(minOrder - widget.orderTotal).toStringAsFixed(2)} more to use this voucher',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ] else if (discount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'You\'ll save \$${discount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Voucher>> _loadAvailableVouchers() async {
    // TODO: Implement actual API call to fetch vouchers
    // For now, return empty list
    // In real implementation:
    // if (widget.shopId != null) {
    //   return ref.read(cartProvider.notifier).getShopVouchers(widget.shopId!);
    // } else {
    //   return ref.read(cartProvider.notifier).getPlatformVouchers();
    // }
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> _applyManualCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a voucher code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement actual voucher validation
      // For now, show placeholder
      if (widget.shopId != null) {
        // await ref.read(cartProvider.notifier).applyShopVoucher(
        //   shopId: widget.shopId!,
        //   code: code,
        // );
      } else {
        // await ref.read(cartProvider.notifier).applyPlatformVoucher(code);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher applied successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyVoucher(Voucher voucher) {
    // TODO: Implement voucher application in Phase 6
    // if (widget.shopId != null) {
    //   ref.read(cartProvider.notifier).applyShopVoucher(
    //     shopId: widget.shopId!,
    //     voucher: voucher,
    //   );
    // } else {
    //   ref.read(cartProvider.notifier).applyPlatformVoucher(voucher);
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voucher ${voucher.code} will be applied')),
    );
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
