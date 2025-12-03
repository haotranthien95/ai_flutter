import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';
import '../../../core/models/address.dart';

/// Address form screen for adding or editing addresses.
class AddressFormScreen extends ConsumerStatefulWidget {
  /// Creates an AddressFormScreen instance.
  const AddressFormScreen({
    super.key,
    this.address,
  });

  /// Address to edit (null for new address).
  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _recipientNameController.text = widget.address!.recipientName;
      _phoneController.text = widget.address!.phoneNumber;
      _streetController.text = widget.address!.streetAddress;
      _wardController.text = widget.address!.ward;
      _districtController.text = widget.address!.district;
      _cityController.text = widget.address!.city;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool success;
    if (widget.address == null) {
      // Add new address
      success = await ref.read(userAddressesProvider.notifier).addAddress(
            recipientName: _recipientNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            streetAddress: _streetController.text.trim(),
            ward: _wardController.text.trim(),
            district: _districtController.text.trim(),
            city: _cityController.text.trim(),
            isDefault: _isDefault,
          );
    } else {
      // Update existing address
      success = await ref.read(userAddressesProvider.notifier).updateAddress(
            addressId: widget.address!.id,
            recipientName: _recipientNameController.text.trim() !=
                    widget.address!.recipientName
                ? _recipientNameController.text.trim()
                : null,
            phoneNumber: _phoneController.text.trim() !=
                    widget.address!.phoneNumber
                ? _phoneController.text.trim()
                : null,
            streetAddress: _streetController.text.trim() !=
                    widget.address!.streetAddress
                ? _streetController.text.trim()
                : null,
            ward: _wardController.text.trim() != widget.address!.ward
                ? _wardController.text.trim()
                : null,
            district:
                _districtController.text.trim() != widget.address!.district
                    ? _districtController.text.trim()
                    : null,
            city: _cityController.text.trim() != widget.address!.city
                ? _cityController.text.trim()
                : null,
          );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address == null
              ? 'Đã thêm địa chỉ mới'
              : 'Đã cập nhật địa chỉ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recipient name
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên người nhận',
                  hintText: 'Nguyễn Văn A',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'họ tên'),
              ),
              const SizedBox(height: 16),
              // Phone number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: '0987654321',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              // Street address
              TextFormField(
                controller: _streetController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  hintText: 'Số nhà, tên đường',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'địa chỉ'),
              ),
              const SizedBox(height: 16),
              // Ward
              TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(
                  labelText: 'Phường/Xã',
                  hintText: 'Phường 1',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'phường/xã'),
              ),
              const SizedBox(height: 16),
              // District
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quận/Huyện',
                  hintText: 'Quận 1',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'quận/huyện'),
              ),
              const SizedBox(height: 16),
              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh/Thành phố',
                  hintText: 'TP. Hồ Chí Minh',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'tỉnh/thành phố'),
              ),
              const SizedBox(height: 16),
              // Set as default checkbox (only for new address)
              if (widget.address == null)
                CheckboxListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: 24),
              // Save button
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.address == null ? 'Thêm địa chỉ' : 'Lưu thay đổi',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
