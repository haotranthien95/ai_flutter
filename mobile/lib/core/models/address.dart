/// Address entity for Vietnamese delivery addresses.
///
/// Uses Vietnamese administrative divisions: City → District → Ward.
class Address {
  /// Creates an address instance.
  const Address({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.ward,
    required this.district,
    required this.city,
    required this.isDefault,
    required this.createdAt,
  });

  /// Address unique identifier (UUID).
  final String id;

  /// User ID who owns this address.
  final String userId;

  /// Recipient's full name.
  final String recipientName;

  /// Recipient's phone number (10 digits starting with 0).
  final String phoneNumber;

  /// Street address (house number, street name, etc.).
  final String streetAddress;

  /// Ward name (Phường/Xã).
  final String ward;

  /// District name (Quận/Huyện).
  final String district;

  /// City/Province name (Thành phố/Tỉnh).
  final String city;

  /// Default shipping address flag.
  final bool isDefault;

  /// Address creation timestamp.
  final DateTime createdAt;

  /// Create Address from JSON.
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipientName: json['recipientName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      streetAddress: json['streetAddress'] as String,
      ward: json['ward'] as String,
      district: json['district'] as String,
      city: json['city'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert Address to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'ward': ward,
      'district': district,
      'city': city,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Address copyWith({
    String? id,
    String? userId,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get full formatted address.
  ///
  /// Format: streetAddress, ward, district, city
  /// Example: "123 Đường ABC, Phường 1, Quận 10, TP. Hồ Chí Minh"
  String get fullAddress {
    return '$streetAddress, $ward, $district, $city';
  }

  /// Get formatted phone number (e.g., "0901 234 567").
  String get formattedPhoneNumber {
    if (phoneNumber.length == 10) {
      return '${phoneNumber.substring(0, 4)} ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  /// Get short address (district and city only).
  ///
  /// Example: "Quận 10, TP. Hồ Chí Minh"
  String get shortAddress {
    return '$district, $city';
  }

  @override
  String toString() {
    return 'Address(id: $id, recipient: $recipientName, fullAddress: $fullAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
