import 'package:flutter/material.dart';

/// Password strength levels.
enum PasswordStrength {
  /// Weak password (< 8 characters or simple).
  weak,

  /// Medium password (8+ characters with some complexity).
  medium,

  /// Strong password (8+ characters with good complexity).
  strong,
}

/// Password strength indicator widget.
///
/// Shows a color-coded bar and text indicating password strength.
class PasswordStrengthIndicator extends StatelessWidget {
  /// Creates a PasswordStrengthIndicator instance.
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  /// Password to evaluate.
  final String password;

  /// Calculate password strength.
  PasswordStrength get _strength {
    if (password.isEmpty || password.length < 8) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length check
    if (password.length >= 12)
      score += 2;
    else if (password.length >= 8) score += 1;

    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) score += 1;

    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;

    // Contains numbers
    if (password.contains(RegExp(r'[0-9]'))) score += 1;

    // Contains special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    if (score >= 5) {
      return PasswordStrength.strong;
    } else if (score >= 3) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  Color get _color {
    switch (_strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get _text {
    switch (_strength) {
      case PasswordStrength.weak:
        return 'Yếu';
      case PasswordStrength.medium:
        return 'Trung bình';
      case PasswordStrength.strong:
        return 'Mạnh';
    }
  }

  double get _progress {
    switch (_strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_color),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          'Độ mạnh mật khẩu: $_text',
          style: TextStyle(
            fontSize: 12,
            color: _color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
