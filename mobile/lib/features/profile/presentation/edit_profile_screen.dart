import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'providers/profile_provider.dart';

/// Edit profile screen.
///
/// Allows users to update their profile information.
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates an EditProfileScreen instance.
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    // Load current user data
    final profileState = ref.read(userProfileProvider);
    profileState.whenData((user) {
      _fullNameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      _avatarUrl = user.avatarUrl;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // In a real app, upload to server and get URL
      // For now, just use the local path as placeholder
      setState(() {
        _avatarUrl = pickedFile.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh đã được chọn'),
          ),
        );
      }
    }
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileState = ref.read(userProfileProvider);
    final currentUser = profileState.value;

    final success = await ref.read(userProfileProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim() != currentUser?.fullName
              ? _fullNameController.text.trim()
              : null,
          email: _emailController.text.trim() != (currentUser?.email ?? '')
              ? (_emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim())
              : null,
          avatarUrl: _avatarUrl != currentUser?.avatarUrl ? _avatarUrl : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    // Email is optional
    if (value == null || value.isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        centerTitle: true,
      ),
      body: profileState.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar picker
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: _showImageSourcePicker,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Full name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateFullName,
                ),
                const SizedBox(height: 16),
                // Phone number (read-only)
                TextFormField(
                  initialValue: user.phoneNumber,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (không bắt buộc)',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 32),
                // Save button
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Không thể tải thông tin: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}
