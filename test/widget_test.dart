import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sidama_way_go/models/user_model.dart';
import 'package:sidama_way_go/providers/auth_provider.dart';
import 'package:sidama_way_go/screens/login_screen.dart';

class TestAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? get userModel => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshUser() async {}

  @override
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.citizen,
    String department = '',
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {}
}

void main() {
  testWidgets('login screen renders without exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: TestAuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Sidama Way Go'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
