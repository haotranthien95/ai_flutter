import 'package:intl/intl.dart';

/// Format Vietnamese currency (VND).
///
/// Example: `formatVND(299000)` → "299.000 ₫"
String formatVND(double amount) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format date to Vietnamese format.
///
/// Example: `formatDate(DateTime(2023, 12, 3))` → "03/12/2023"
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Format date with time to Vietnamese format.
///
/// Example: `formatDateTime(DateTime.now())` → "03/12/2023 15:30"
String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}

/// Format Vietnamese phone number.
///
/// Example: `formatPhoneNumber("0901234567")` → "0901 234 567"
String formatPhoneNumber(String phoneNumber) {
  // Remove any non-digit characters
  final String cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');

  // Format as "0901 234 567" (4-3-3)
  if (cleaned.length == 10 && cleaned.startsWith('0')) {
    return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
  }

  // Return original if not valid format
  return phoneNumber;
}

/// Format relative time in Vietnamese.
///
/// Example: `formatRelativeTime(DateTime.now().subtract(Duration(minutes: 5)))` → "5 phút trước"
String formatRelativeTime(DateTime dateTime) {
  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Vừa xong';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  } else if (difference.inDays < 30) {
    final int weeks = (difference.inDays / 7).floor();
    return '$weeks tuần trước';
  } else if (difference.inDays < 365) {
    final int months = (difference.inDays / 30).floor();
    return '$months tháng trước';
  } else {
    final int years = (difference.inDays / 365).floor();
    return '$years năm trước';
  }
}

/// Format large numbers with K/M suffix.
///
/// Example: `formatCompactNumber(1500)` → "1.5K"
String formatCompactNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}

/// Format percentage.
///
/// Example: `formatPercentage(0.25)` → "25%"
String formatPercentage(double value, {int decimalPlaces = 0}) {
  return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
}

/// Format file size.
///
/// Example: `formatFileSize(1536000)` → "1.5 MB"
String formatFileSize(int bytes) {
  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  int unitIndex = 0;
  double size = bytes.toDouble();

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
}

/// Format distance in kilometers.
///
/// Example: `formatDistance(1500)` → "1.5 km"
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toInt()} m';
  } else {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Truncate text with ellipsis.
///
/// Example: `truncate("Long text here", 10)` → "Long text..."
String truncate(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

/// Format Vietnamese address (short version).
///
/// Example: `formatShortAddress(ward: "Phường 1", district: "Quận 10", city: "TP. HCM")` → "P.1, Q.10, TP. HCM"
String formatShortAddress({
  required String ward,
  required String district,
  required String city,
}) {
  final String shortWard = ward.replaceAll('Phường ', 'P.').replaceAll('Xã ', 'X.');
  final String shortDistrict = district.replaceAll('Quận ', 'Q.').replaceAll('Huyện ', 'H.');
  final String shortCity = city.replaceAll('Thành phố ', 'TP. ').replaceAll('Tỉnh ', '');

  return '$shortWard, $shortDistrict, $shortCity';
}
