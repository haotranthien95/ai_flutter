import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/auth_state.dart';

/// OTP verification screen.
///
/// Verifies phone number with 6-digit OTP code.
class OTPVerificationScreen extends ConsumerStatefulWidget {
  /// Creates an OTPVerificationScreen instance.
  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  /// Phone number to verify.
  final String phoneNumber;

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOTP(
          phoneNumber: widget.phoneNumber,
          otpCode: _otpCode,
        );

    if (success && mounted) {
      // Navigate to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    // In real app, this would call register again or a resend OTP endpoint
    // For now, just restart the timer
    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP đã được gửi lại'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        // Last field, unfocus
        _otpFocusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
        title: const Text('Xác thực OTP'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Icon
              const Icon(
                Icons.phone_android,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              // Instructions
              Text(
                'Nhập mã OTP',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Mã xác thực đã được gửi đến số\n${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _onOtpChanged(index, value),
                      enabled: !authState.maybeWhen(
                        loading: () => true,
                        orElse: () => false,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Timer and resend button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    Text(
                      'Gửi lại mã sau $_formattedTime',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ] else ...[
                    const Text('Chưa nhận được mã?'),
                    TextButton(
                      onPressed: _handleResend,
                      child: const Text('Gửi lại'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              // Verify button
              ElevatedButton(
                onPressed: authState.maybeWhen(
                  loading: () => null,
                  orElse: () => _handleVerify,
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
                    'Xác thực',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
