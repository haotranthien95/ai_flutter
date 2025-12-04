import 'package:intl/intl.dart';

/// User role enum.
enum UserRole {
  /// Guest user (not authenticated).
  guest,

  /// Regular buyer account.
  buyer,

  /// Seller with shop.
  seller,

  /// Platform administrator.
  admin;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (UserRole e) => e.name == value,
      orElse: () => UserRole.guest,
    );
  }
}

/// User entity representing all platform users.
///
/// Supports guest, buyer, seller, and admin roles with role transitions.
class User {
  /// Creates a user instance.
  const User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.passwordHash,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.isVerified,
    required this.isSuspended,
    required this.createdAt,
    required this.updatedAt,
  });

  /// User unique identifier (UUID).
  final String id;

  /// Vietnamese phone number (10 digits starting with 0).
  final String phoneNumber;

  /// Email address (optional, used for password recovery).
  final String? email;

  /// Hashed password (null for guest accounts).
  final String? passwordHash;

  /// Full name in Vietnamese format (e.g., "Nguyễn Văn A").
  final String? fullName;

  /// Profile picture URL.
  final String? avatarUrl;

  /// User role (GUEST, BUYER, SELLER, ADMIN).
  final UserRole role;

  /// Phone number verified via OTP.
  final bool isVerified;

  /// Account suspended by admin (cannot login).
  final bool isSuspended;

  /// Account creation timestamp.
  final DateTime createdAt;

  /// Last profile update timestamp.
  final DateTime updatedAt;

  /// Create User from JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      passwordHash: json['passwordHash'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      isSuspended: json['isSuspended'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert User to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'role': role.toJson(),
      'isVerified': isVerified,
      'isSuspended': isSuspended,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  User copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? passwordHash,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (fullName or phone number).
  String get displayName => fullName ?? phoneNumber;

  /// Get formatted phone number (e.g., "0901 234 567").
  String get formattedPhoneNumber {
    if (phoneNumber.length == 10) {
      return '${phoneNumber.substring(0, 4)} ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  /// Get formatted created date (e.g., "03/12/2023").
  String get formattedCreatedDate {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  /// Check if user can create a shop (must be verified buyer).
  bool get canCreateShop =>
      role == UserRole.buyer && isVerified && !isSuspended;

  /// Check if user has admin privileges.
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is a seller.
  bool get isSeller => role == UserRole.seller;

  /// Check if user is a buyer.
  bool get isBuyer => role == UserRole.buyer;

  /// Check if user is a guest.
  bool get isGuest => role == UserRole.guest;

  @override
  String toString() {
    return 'User(id: $id, phoneNumber: $phoneNumber, role: $role, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
