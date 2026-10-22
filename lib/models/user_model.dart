import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

enum UserRole {
  superAdmin,
  oldTerminalAdmin,
  newTerminalAdmin,
  taxiAdmin,
  tourismAdmin,
  hotelAdmin,
  healthAdmin,
  pharmacyAdmin,
  emergencyAdmin,
  churchAdmin,
  businessAdmin,
  governmentFleetAdmin,
  taxiDriver,
  citizen
}

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String photo;
  final UserRole role;
  final String language;
  final String department;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String status; // active, suspended, etc.
  final bool isApproved;
  final bool isActive;
  final double walletBalance;
  final String membershipNumber;
  final int unreadNotifications;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photo = '',
    required this.role,
    this.language = 'en',
    required this.department,
    required this.createdAt,
    required this.lastLogin,
    this.status = 'active',
    this.isApproved = true,
    this.isActive = true,
    this.walletBalance = 0.0,
    this.membershipNumber = '',
    this.unreadNotifications = 0,
  });

  /// Normalizes any role string to a canonical version.
  static String normalizeRole(String? role) {
    if (role == null || role.isEmpty) return 'citizen';
    final r = role.toLowerCase().trim();
    
    if (r.contains('admin') && r.contains('super')) return 'admin';
    if (r == 'admin') return 'admin';
    
    if (r.contains('taxi') && r.contains('admin')) return 'taxi';
    if (r == 'taxi') return 'taxi';
    
    if (r.contains('new') && r.contains('terminal')) return 'new_terminal';
    if (r == 'new_terminal') return 'new_terminal';
    
    if (r.contains('old') && r.contains('terminal')) return 'old_terminal';
    if (r == 'old_terminal') return 'old_terminal';
    
    if (r.contains('tourism')) return 'tourism';
    if (r.contains('hotel')) return 'hotel';
    
    if (r.contains('health') || r.contains('hospital')) return 'health';
    if (r.contains('pharmacy')) return 'pharmacy';
    if (r.contains('emergency')) return 'emergency';
    
    if (r.contains('government') && r.contains('fleet')) return 'government_fleet';
    if (r.contains('church')) return 'church';
    if (r.contains('business')) return 'business';
    
    if (r.contains('driver')) return 'taxi_driver';
    
    return 'citizen';
  }

  /// Maps a canonical role string back to UserRole enum.
  static UserRole parseUserRole(String? role) {
    final canonical = normalizeRole(role);
    switch (canonical) {
      case 'admin': return UserRole.superAdmin;
      case 'new_terminal': return UserRole.newTerminalAdmin;
      case 'old_terminal': return UserRole.oldTerminalAdmin;
      case 'taxi': return UserRole.taxiAdmin;
      case 'tourism': return UserRole.tourismAdmin;
      case 'hotel': return UserRole.hotelAdmin;
      case 'health': return UserRole.healthAdmin;
      case 'pharmacy': return UserRole.pharmacyAdmin;
      case 'emergency': return UserRole.emergencyAdmin;
      case 'government_fleet': return UserRole.governmentFleetAdmin;
      case 'church': return UserRole.churchAdmin;
      case 'business': return UserRole.businessAdmin;
      case 'taxi_driver': return UserRole.taxiDriver;
      default: return UserRole.citizen;
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Extract role from multiple possible field names and normalize it
    final roleValue = map['role']?.toString() ?? 
                     map['userType']?.toString() ?? 
                     map['user_type']?.toString() ?? 
                     '';
    
    final parsedRole = parseUserRole(roleValue);

    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['phone_number'] ?? '',
      photo: map['photo'] ?? map['photo_url'] ?? map['avatar_url'] ?? '',
      role: parsedRole,
      language: map['language'] ?? 'en',
      department: map['department'] ?? '',
      createdAt: FirestoreUtils.parseDateTime(map['createdAt'] ?? map['created_at']) ?? DateTime.now(),
      lastLogin: FirestoreUtils.parseDateTime(map['lastLogin'] ?? map['last_login']) ?? DateTime.now(),
      status: map['status'] ?? 'active',
      isApproved: (map['isApproved'] ?? map['is_approved'] ?? true) as bool,
      isActive: (map['isActive'] ?? map['is_active'] ?? true) as bool,
      walletBalance: (map['walletBalance'] ?? map['wallet_balance'] ?? 0.0).toDouble(),
      membershipNumber: map['membershipNumber'] ?? map['membership_number'] ?? '',
      unreadNotifications: (map['unreadNotifications'] ?? map['unread_notifications'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photo': photo,
      'role': normalizeRole(role.name), // Always store canonical version
      'language': language,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'status': status,
      'isApproved': isApproved,
      'isActive': isActive,
      'walletBalance': walletBalance,
      'membershipNumber': membershipNumber,
      'unreadNotifications': unreadNotifications,
    };
  }
}
