import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/address.dart';
import '../../profile/presentation/providers/profile_provider.dart';

/// Address selector screen for checkout (T154).
///
/// Allows users to select or add delivery address.
class AddressSelectorScreen extends ConsumerStatefulWidget {
  const AddressSelectorScreen({super.key});

  @override
  ConsumerState<AddressSelectorScreen> createState() =>
      _AddressSelectorScreenState();
}

class _AddressSelectorScreenState
    extends ConsumerState<AddressSelectorScreen> {
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    // Load addresses when screen opens
    Future.microtask(() {
      ref.read(userAddressesProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(userAddressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
        actions: [
          TextButton.icon(
            onPressed: () => _navigateToAddAddress(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
          ),
        ],
      ),
      body: addressesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không thể tải địa chỉ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(userAddressesProvider.notifier).loadAddresses();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return _buildEmptyState();
          }

          // Set default address as selected if not already selected
          if (_selectedAddressId == null) {
            final defaultAddress = addresses.firstWhere(
              (addr) => addr.isDefault,
              orElse: () => addresses.first,
            );
            _selectedAddressId = defaultAddress.id;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: addresses.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _buildAddressCard(address);
                  },
                ),
              ),
              _buildConfirmButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có địa chỉ giao hàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng thêm địa chỉ để tiếp tục đặt hàng',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddAddress(),
              icon: const Icon(Icons.add_location),
              label: const Text('Thêm địa chỉ mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddressId == address.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddressId = address.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: address.id,
                    groupValue: _selectedAddressId,
                    onChanged: (value) {
                      setState(() {
                        _selectedAddressId = value;
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              address.recipientName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Mặc định',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.formattedPhoneNumber,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _navigateToEditAddress(address),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  address.fullAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedAddressId != null ? _confirmSelection : null,
            child: const Text('Xác nhận địa chỉ'),
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedAddressId != null) {
      Navigator.pop(context, _selectedAddressId);
    }
  }

  void _navigateToAddAddress() {
    // TODO: Navigate to add address screen (Phase 4 profile feature)
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng thêm địa chỉ đang phát triển (Phase 4)'),
      ),
    );
  }

  void _navigateToEditAddress(Address address) {
    // TODO: Navigate to edit address screen (Phase 4 profile feature)
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng chỉnh sửa địa chỉ đang phát triển (Phase 4)'),
      ),
    );
  }
}
