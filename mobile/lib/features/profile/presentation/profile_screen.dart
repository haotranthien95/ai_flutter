import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'address_list_screen.dart';

/// Profile screen showing user information and options.
///
/// Displays user avatar, name, contact info, and navigation to
/// profile management features.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a ProfileScreen instance.
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile when screen opens
    Future.microtask(
        () => ref.read(userProfileProvider.notifier).loadProfile());
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
      ),
      body: profileState.when(
        data: (user) => SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              // User name
              Text(
                user.fullName ?? 'Người dùng',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Phone number
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    user.phoneNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              // Email (if available)
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              // Edit Profile Button
              _ProfileMenuItem(
                icon: Icons.edit,
                title: 'Chỉnh sửa thông tin',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // Manage Addresses Button
              _ProfileMenuItem(
                icon: Icons.location_on,
                title: 'Quản lý địa chỉ',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddressListScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // My Orders Button (placeholder for US-004)
              _ProfileMenuItem(
                icon: Icons.shopping_bag,
                title: 'Đơn hàng của tôi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang được phát triển'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // Settings Button (placeholder)
              _ProfileMenuItem(
                icon: Icons.settings,
                title: 'Cài đặt',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang được phát triển'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              // Logout Button
              _ProfileMenuItem(
                icon: Icons.logout,
                title: 'Đăng xuất',
                iconColor: Colors.red,
                titleColor: Colors.red,
                onTap: _handleLogout,
              ),
              const Divider(height: 1),
              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thông tin',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(userProfileProvider.notifier).loadProfile(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile menu item widget.
class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
