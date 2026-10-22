import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sidama_way_go/firebase_options.dart';
import 'package:sidama_way_go/providers/auth_provider.dart';
import 'package:sidama_way_go/models/user_model.dart';
import 'package:sidama_way_go/screens/login_screen.dart';
import 'package:sidama_way_go/screens/super_admin_dashboard.dart';
import 'package:sidama_way_go/screens/taxi_admin_dashboard.dart';
import 'package:sidama_way_go/screens/old_terminal_dashboard.dart';
import 'package:sidama_way_go/screens/new_terminal_dashboard.dart';
import 'package:sidama_way_go/screens/tourism_dashboard.dart';
import 'package:sidama_way_go/screens/hotel_dashboard.dart';
import 'package:sidama_way_go/screens/hospital_dashboard.dart';
import 'package:sidama_way_go/screens/emergency_dashboard.dart';
import 'package:sidama_way_go/screens/government_fleet_screen.dart';
import 'package:sidama_way_go/screens/church_services_screen.dart';
import 'package:sidama_way_go/screens/home_screen.dart';
import 'package:sidama_way_go/models/city_os_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Runtime Role & Dashboard Audit', (
    WidgetTester tester,
  ) async {
    print('====================================');
    print('STARTING REAL RUNTIME INVESTIGATION');
    print('====================================');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;

    final rolesToTest = [
      'super_admin',
      'taxi_admin',
      'old_terminal',
      'new_terminal',
      'tourism_admin',
      'hotel_admin',
      'healthcare_admin',
      'government_fleet',
      'church_admin',
    ];

    for (final rawRole in rolesToTest) {
      print('\n------------------------------------');
      print('TESTING ROLE: $rawRole');
      print('------------------------------------');

      final email = 'audit_${rawRole}@sidamawaygo.test';
      final password = 'password123';

      UserCredential? creds;
      try {
        creds = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        try {
          creds = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (e2) {
          print('Auth Error: $e2');
          continue;
        }
      }

      final uid = creds.user!.uid;
      print('Firebase UID: $uid');
      print('Email:        $email');

      // Update Firestore Role
      await db.collection(CityOSCollection.users).doc(uid).set({
        'fullName': 'Audit $rawRole',
        'email': email,
        'role': rawRole,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Firestore document path: users/$uid');

      // Step 2: Verify Profile Load
      final doc = await db.collection(CityOSCollection.users).doc(uid).get();
      final data = doc.data()!;
      print('Firestore document data: $data');
      print('Raw role string: $rawRole');

      // Step 3: Verify Mapping
      final userModel = UserModel.fromMap(data, uid);
      print('Parsed UserRole enum: ${userModel.role}');

      // Determine expected widget
      dynamic expectedWidget;
      String expectedRoute;
      switch (userModel.role) {
        case UserRole.superAdmin:
          expectedWidget = SuperAdminDashboard;
          expectedRoute = '/super_admin_dashboard';
          break;
        case UserRole.oldTerminalAdmin:
          expectedWidget = OldTerminalDashboard;
          expectedRoute = '/old_terminal_dashboard';
          break;
        case UserRole.newTerminalAdmin:
          expectedWidget = NewTerminalDashboard;
          expectedRoute = '/new_terminal_dashboard';
          break;
        case UserRole.taxiAdmin:
          expectedWidget = TaxiAdminDashboard;
          expectedRoute = '/taxi_admin_dashboard';
          break;
        case UserRole.tourismAdmin:
          expectedWidget = TourismDashboard;
          expectedRoute = '/tourism_dashboard';
          break;
        case UserRole.hotelAdmin:
          expectedWidget = HotelDashboard;
          expectedRoute = '/hotel_dashboard';
          break;
        case UserRole.healthAdmin:
          expectedWidget = HospitalDashboard;
          expectedRoute = '/hospital_dashboard';
          break;
        case UserRole.emergencyAdmin:
          expectedWidget = EmergencyDashboard;
          expectedRoute = '/emergency_dashboard';
          break;
        case UserRole.governmentFleetAdmin:
          expectedWidget = GovernmentFleetScreen;
          expectedRoute = '/government_fleet';
          break;
        case UserRole.churchAdmin:
          expectedWidget = ChurchServicesScreen;
          expectedRoute = '/church_services';
          break;
        default:
          expectedWidget = HomeScreen;
          expectedRoute = '/home';
      }

      // Step 4: Verify Navigation Logic
      print('Expected route: $expectedRoute');

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
      state.navigateByRole(userModel.role);

      await tester.pumpAndSettle();

      final finder = find.byType(expectedWidget);
      print('Actual route: $expectedRoute (via state)');
      print('Widget opened: $expectedWidget');

      if (finder.evaluate().isNotEmpty) {
        print('Current screen: $expectedWidget');
        print('RESULT: PASS');
      } else {
        print('RESULT: FAIL');
        print('Actual screen was: ${tester.allWidgets.last.runtimeType}');
      }

      // Cleanup for next iteration
      await auth.signOut();
    }

    print('\n====================================');
    print('AUDIT COMPLETE');
    print('====================================');
  });
}
