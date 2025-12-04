import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/auth_state.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';
import 'widgets/password_strength_indicator.dart';

/// Registration screen for new user sign up.
///
/// Collects user information and navigates to OTP verification.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates a RegisterScreen instance.
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref.read(authProvider.notifier).register(
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        );

    if (user != null && mounted) {
      // Navigate to OTP verification
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            phoneNumber: _phoneController.text.trim(),
          ),
        ),
      );
    }
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
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
    final authState = ref.watch(authProvider);

    // Show error snackbar
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.whenOrNull(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Full name input
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateFullName,
                  enabled: !authState.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
                const SizedBox(height: 16),
                // Phone number input
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
                  enabled: !authState.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
                const SizedBox(height: 16),
                // Email input (optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (không bắt buộc)',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  enabled: !authState.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
                const SizedBox(height: 16),
                // Password input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Tối thiểu 8 ký tự',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                  onChanged: (_) =>
                      setState(() {}), // Trigger rebuild for strength indicator
                  enabled: !authState.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                PasswordStrengthIndicator(
                  password: _passwordController.text,
                ),
                const SizedBox(height: 16),
                // Confirm password input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateConfirmPassword,
                  enabled: !authState.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
                const SizedBox(height: 24),
                // Register button
                ElevatedButton(
                  onPressed: authState.maybeWhen(
                    loading: () => null,
                    orElse: () => _handleRegister,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.maybeWhen(
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    orElse: () => const Text(
                      'Đăng ký',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
