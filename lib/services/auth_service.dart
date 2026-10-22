import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart';
import 'audit_service.dart';
import 'api/auth_api_service.dart';
import '../core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthApiService _authApiService = AuthApiService();
  GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Lazy initialization of GoogleSignIn to prevent startup crashes on Web
  /// when Client ID is not configured.
  GoogleSignIn? get googleSignIn {
    if (kIsWeb) {
      // In a real production app, we would check if a client ID is provided 
      // via a config or environmental variable.
      // For now, we return null or handle gracefully during the actual call.
      return null; 
    }
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn;
  }

  /// Get user role from Firestore profile
  Future<String> _getUserRoleFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection(CityOSCollection.users).doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Try multiple possible field names for role
        final rawRole = data['role']?.toString() ?? 
                        data['userType']?.toString() ?? 
                        data['user_type']?.toString() ?? 
                        'citizen';
        final normalized = UserModel.normalizeRole(rawRole);
        AppLogger.info('Firestore role found: $rawRole (normalized: $normalized) for UID: $uid');
        return normalized;
      }
    } catch (e) {
      AppLogger.warning('Failed to read role from Firestore for $uid: $e');
    }
    return 'citizen';
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      AppLogger.info('Fetching profile for UID: $uid from Supabase');
      
      // Fetch user profile from Supabase via Next.js API
      final userData = await _authApiService.getUserProfile(uid);
      
      AppLogger.info('Profile found for $uid');
      return UserModel.fromMap(userData, uid);
    } catch (e) {
      AppLogger.error('Error getting user data for $uid', error: e);
    }
    return null;
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final uid = result.user!.uid;
      AppLogger.info('--- LOGIN SUCCESS ---');
      AppLogger.info('User UID: $uid');
      AppLogger.info('Email: ${result.user!.email}');

      // 1. Read authoritative role from Firestore first
      final firestoreRole = await _getUserRoleFromFirestore(uid);
      AppLogger.info('Authoritative role: $firestoreRole');

      // 2. Sync user with Supabase via Next.js API (upsert - returns user profile)
      UserModel? userProfile;
      try {
        final userData = await _authApiService.syncUser(
          firebaseUid: uid,
          email: result.user!.email ?? email,
          fullName: result.user!.displayName,
          phone: result.user!.phoneNumber,
          role: firestoreRole,
          userType: firestoreRole,
        );
        userProfile = UserModel.fromMap(userData, uid);
        AppLogger.info('User profile synced from backend: ${userProfile.role.name}');
      } catch (syncError) {
        AppLogger.warning('Backend sync failed (non-critical): $syncError');
        // Construct fallback model using Firestore role
        userProfile = UserModel(
          uid: uid,
          fullName: result.user!.displayName ?? email.split('@')[0],
          email: result.user!.email ?? email,
          phone: result.user!.phoneNumber ?? '',
          role: UserModel.parseUserRole(firestoreRole),
          department: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        AppLogger.info('Using local fallback profile with role: ${userProfile.role.name}');
      }

      // Log non-critical audit action
      _logAuditSafe('User Login', 'Email: ${result.user!.email}');

      return userProfile;
    } catch (e) {
      AppLogger.error('Login error', error: e);
      rethrow;
    }
  }

  Future<void> _logAuditSafe(String action, String details) async {
    try {
      await AuditService.logAction(action, details: details);
    } catch (e) {
      AppLogger.warning('Failed to log audit action: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.citizen,
    String department = '',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      final uid = result.user!.uid;
      AppLogger.info('--- REGISTRATION SUCCESS ---');
      AppLogger.info('User UID: $uid');
      AppLogger.info('Email: $email');

      // 1. Determine canonical role
      final canonicalRole = UserModel.normalizeRole(role.name);
      AppLogger.info('Canonical role for registration: $canonicalRole');

      // 2. Sync user with Supabase via Next.js API (upsert - returns user profile)
      UserModel? userProfile;
      try {
        final userData = await _authApiService.syncUser(
          firebaseUid: uid,
          email: email,
          fullName: fullName,
          phone: phone,
          role: canonicalRole,
          userType: canonicalRole,
        );
        userProfile = UserModel.fromMap(userData, uid);
        AppLogger.info('User registered and synced with backend: ${userProfile.role.name}');
      } catch (syncError) {
        AppLogger.warning('Backend sync failed (non-critical): $syncError');
        // Construct fallback model
        userProfile = UserModel(
          uid: uid,
          fullName: fullName,
          email: email,
          phone: phone,
          role: role,
          department: department,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

      return userProfile;
    } catch (e) {
      AppLogger.error('Registration error', error: e);
      rethrow;
    }
  }

  // Additional authentication methods

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent to: $email');
    } catch (e) {
      AppLogger.error('Password reset error', error: e);
      rethrow;
    }
  }

  Future<UserModel?> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? photo,
  }) async {
    try {
      // Update Firebase profile
      if (photo != null) {
        await _auth.currentUser?.updatePhotoURL(photo);
      }

      // Update Supabase profile via API (upsert - returns user profile)
      UserModel? userProfile;
      
      // We always sync to ensure Supabase is updated when profile changes
      try {
        final syncedData = await _authApiService.syncUser(
          firebaseUid: uid,
          email: _auth.currentUser?.email ?? '',
          fullName: fullName,
          phone: phone,
        );
        userProfile = UserModel.fromMap(syncedData, uid);
      } catch (syncError) {
        AppLogger.warning('Backend sync failed (non-critical): $syncError');
      }

      AppLogger.info('Profile updated successfully');
      return userProfile;
    } catch (e) {
      AppLogger.error('Profile update error', error: e);
      rethrow;
    }
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      if (googleSignIn == null) {
        throw Exception('Google Sign-In is not configured for this platform.');
      }
      
      final GoogleSignInAccount? googleUser = await googleSignIn!.signIn();
      if (googleUser == null) {
        AppLogger.warning('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      
      final uid = result.user!.uid;
      AppLogger.info('--- GOOGLE LOGIN SUCCESS ---');
      AppLogger.info('User UID: $uid');

      // 1. Read role from Firestore profile
      final firestoreRole = await _getUserRoleFromFirestore(uid);

      // 2. Sync user with Supabase
      UserModel? userProfile;
      try {
        final userData = await _authApiService.syncUser(
          firebaseUid: uid,
          email: result.user!.email ?? googleUser.email,
          fullName: result.user!.displayName ?? googleUser.displayName,
          phone: result.user!.phoneNumber,
          role: firestoreRole,
          userType: firestoreRole,
        );
        userProfile = UserModel.fromMap(userData, uid);
      } catch (syncError) {
        AppLogger.warning('Backend sync failed: $syncError');
        userProfile = UserModel(
          uid: uid,
          fullName: result.user!.displayName ?? googleUser.displayName ?? '',
          email: result.user!.email ?? googleUser.email,
          phone: result.user!.phoneNumber ?? '',
          role: UserModel.parseUserRole(firestoreRole),
          department: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

      _logAuditSafe('Google Login', 'Email: ${result.user!.email}');
      return userProfile;
    } catch (e) {
      AppLogger.error('Google Sign-In error', error: e);
      rethrow;
    }
  }

  // Phone Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
    } catch (e) {
      AppLogger.error('Phone verification error', error: e);
      rethrow;
    }
  }

  Future<UserModel?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      
      final uid = result.user!.uid;
      AppLogger.info('--- PHONE LOGIN SUCCESS ---');
      AppLogger.info('User UID: $uid');

      // 1. Read role from Firestore
      final firestoreRole = await _getUserRoleFromFirestore(uid);

      // 2. Sync user with Supabase
      UserModel? userProfile;
      try {
        final userData = await _authApiService.syncUser(
          firebaseUid: uid,
          email: result.user!.email ?? '',
          phone: result.user!.phoneNumber,
          role: firestoreRole,
          userType: firestoreRole,
        );
        userProfile = UserModel.fromMap(userData, uid);
      } catch (syncError) {
        AppLogger.warning('Backend sync failed: $syncError');
        userProfile = UserModel(
          uid: uid,
          fullName: result.user!.displayName ?? '',
          email: result.user!.email ?? '',
          phone: result.user!.phoneNumber ?? '',
          role: UserModel.parseUserRole(firestoreRole),
          department: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

      _logAuditSafe('Phone Login', 'Phone: ${result.user!.phoneNumber}');

      return userProfile;
    } catch (e) {
      AppLogger.error('Phone OTP error', error: e);
      rethrow;
    }
  }
}
