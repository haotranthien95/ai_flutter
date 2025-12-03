/// Check if a string is a valid Vietnamese phone number.
///
/// Valid format: 10 digits starting with 0.
/// Examples: 0901234567, 0123456789
bool isValidVietnamesePhone(String phone) {
  // Remove any whitespace or special characters
  final String cleaned = phone.replaceAll(RegExp(r'\s+'), '');

  // Check format: 10 digits starting with 0
  final RegExp phoneRegex = RegExp(r'^0\d{9}$');
  return phoneRegex.hasMatch(cleaned);
}

/// Check if a string is a valid email address.
bool isValidEmail(String email) {
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email.trim());
}

/// Check if a price is valid (positive number).
bool isValidPrice(double price) {
  return price > 0;
}

/// Check if a product title is valid.
///
/// Rules:
/// - Not empty
/// - At least 10 characters
/// - Maximum 200 characters
bool isValidProductTitle(String title) {
  final String trimmed = title.trim();
  return trimmed.isNotEmpty && trimmed.length >= 10 && trimmed.length <= 200;
}

/// Check if a password is valid.
///
/// Rules:
/// - At least 8 characters
/// - Contains at least one letter
/// - Contains at least one number
bool isValidPassword(String password) {
  if (password.length < 8) {
    return false;
  }

  // Check for at least one letter
  final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);

  // Check for at least one number
  final bool hasNumber = RegExp(r'\d').hasMatch(password);

  return hasLetter && hasNumber;
}

/// Check if a string is a valid Vietnamese name.
///
/// Rules:
/// - Not empty
/// - At least 2 characters
/// - Maximum 100 characters
/// - Contains only Vietnamese letters, spaces, and hyphens
bool isValidVietnameseName(String name) {
  final String trimmed = name.trim();

  if (trimmed.isEmpty || trimmed.length < 2 || trimmed.length > 100) {
    return false;
  }

  // Allow Vietnamese characters, spaces, and hyphens
  final RegExp nameRegex = RegExp(
    r'^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ\s-]+$',
  );

  return nameRegex.hasMatch(trimmed);
}

/// Check if a string is a valid shop name.
///
/// Rules:
/// - Not empty
/// - At least 3 characters
/// - Maximum 100 characters
bool isValidShopName(String shopName) {
  final String trimmed = shopName.trim();
  return trimmed.isNotEmpty && trimmed.length >= 3 && trimmed.length <= 100;
}

/// Check if a quantity is valid.
///
/// Rules:
/// - Positive integer
/// - Maximum 999 (reasonable limit for cart quantities)
bool isValidQuantity(int quantity) {
  return quantity > 0 && quantity <= 999;
}

/// Check if a discount percentage is valid.
///
/// Rules:
/// - Between 1 and 100
bool isValidDiscountPercentage(double percentage) {
  return percentage >= 1 && percentage <= 100;
}

/// Check if a rating is valid.
///
/// Rules:
/// - Between 1 and 5 (inclusive)
bool isValidRating(int rating) {
  return rating >= 1 && rating <= 5;
}

/// Check if a URL is valid.
bool isValidUrl(String url) {
  final RegExp urlRegex = RegExp(
    r'^https?://[a-zA-Z0-9\-._~:/?#\[\]@!$&()*+,;=%]+$',
  );
  return urlRegex.hasMatch(url.trim());
}

/// Check if a voucher code is valid format.
///
/// Rules:
/// - 4-20 characters
/// - Only uppercase letters, numbers, and hyphens
bool isValidVoucherCode(String code) {
  final String trimmed = code.trim().toUpperCase();

  if (trimmed.length < 4 || trimmed.length > 20) {
    return false;
  }

  final RegExp codeRegex = RegExp(r'^[A-Z0-9-]+$');
  return codeRegex.hasMatch(trimmed);
}

/// Get password strength (0-4).
///
/// Returns:
/// - 0: Very weak
/// - 1: Weak
/// - 2: Fair
/// - 3: Good
/// - 4: Strong
int getPasswordStrength(String password) {
  int strength = 0;

  // Length check
  if (password.length >= 8) strength++;
  if (password.length >= 12) strength++;

  // Character variety checks
  if (RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[A-Z]').hasMatch(password)) {
    strength++;
  }

  if (RegExp(r'\d').hasMatch(password)) strength++;

  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

  return strength.clamp(0, 4);
}

/// Get password strength label in Vietnamese.
String getPasswordStrengthLabel(int strength) {
  switch (strength) {
    case 0:
      return 'Rất yếu';
    case 1:
      return 'Yếu';
    case 2:
      return 'Trung bình';
    case 3:
      return 'Tốt';
    case 4:
      return 'Mạnh';
    default:
      return 'Không xác định';
  }
}
