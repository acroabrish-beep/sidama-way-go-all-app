import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = true;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userModel != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _userModel = null;
        _isLoading = false;
        notifyListeners();
      } else {
        // Initial state restoration: Check if we have a valid profile.
        // We only call GET here for session persistence.
        // During explicit Login/Register, the AuthService returns the model directly from POST.
        try {
          final profile = await _authService.getUserData(user.uid);
          _userModel = profile;
        } catch (e) {
          AppLogger.warning('Failed to restore session profile: $e');
          _userModel = null;
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // signIn now returns UserModel directly from POST sync (upsert)
      final profile = await _authService.signIn(email, password);
      _userModel = profile;
      
      if (_userModel == null) {
        AppLogger.warning('Backend sync failed or returned empty profile');
        throw Exception('Authentication synchronization failed.');
      }
    } catch (e) {
      _userModel = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_userModel != null) {
      try {
        final refreshedProfile = await _authService.getUserData(_userModel!.uid);
        if (refreshedProfile != null) {
          _userModel = refreshedProfile;
        }
      } catch (e) {
        AppLogger.warning('Failed to refresh user profile: $e');
      }
      notifyListeners();
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.citizen,
    String department = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _authService.registerUser(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        department: department,
      );
      _userModel = profile;
      
      if (_userModel == null) {
        AppLogger.warning('Backend sync failed during registration');
        throw Exception('Registration synchronization failed.');
      }
    } catch (e) {
      _userModel = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _authService.signInWithGoogle();
      _userModel = profile;
    } catch (e) {
      _userModel = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _authService.signInWithOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _userModel = profile;
    } catch (e) {
      _userModel = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
