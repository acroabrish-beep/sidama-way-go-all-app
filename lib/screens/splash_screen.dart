import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'super_admin_dashboard.dart';
import 'taxi_admin_dashboard.dart';
import 'old_terminal_dashboard.dart';
import 'new_terminal_dashboard.dart';
import 'tourism_dashboard.dart';
import 'hotel_dashboard.dart';
import 'hospital_dashboard.dart';
import 'pharmacy_dashboard.dart';
import 'emergency_dashboard.dart';
import 'government_fleet_screen.dart';
import 'church_services_screen.dart';
import '../core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Session restoration is asynchronous (profile fetch over the network).
    // Wait for it instead of trusting the fixed delay, otherwise a signed-in
    // user can be routed to Login on a slow connection. Bounded so the app
    // never hangs on the splash screen.
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (authProvider.isLoading && mounted && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      final user = authProvider.userModel;
      if (user != null) {
        _navigateByRole(user.role);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateByRole(UserRole role) {
    Widget nextScreen;
    AppLogger.info('Splash: Navigating by role: ${role.name}');

    switch (role) {
      case UserRole.superAdmin:
        nextScreen = const SuperAdminDashboard();
        break;
      case UserRole.oldTerminalAdmin:
        nextScreen = const OldTerminalDashboard();
        break;
      case UserRole.newTerminalAdmin:
        nextScreen = const NewTerminalDashboard();
        break;
      case UserRole.taxiAdmin:
        nextScreen = const TaxiAdminDashboard();
        break;
      case UserRole.tourismAdmin:
        nextScreen = const TourismDashboard();
        break;
      case UserRole.hotelAdmin:
        nextScreen = const HotelDashboard();
        break;
      case UserRole.healthAdmin:
        nextScreen = const HospitalDashboard();
        break;
      case UserRole.pharmacyAdmin:
        nextScreen = const PharmacyDashboard();
        break;
      case UserRole.emergencyAdmin:
        nextScreen = const EmergencyDashboard();
        break;
      case UserRole.governmentFleetAdmin:
        nextScreen = const GovernmentFleetScreen();
        break;
      case UserRole.churchAdmin:
        nextScreen = const ChurchServicesScreen();
        break;
      case UserRole.businessAdmin:
      case UserRole.citizen:
      case UserRole.taxiDriver:
        nextScreen = const HomeScreen();
        break;
    }

    AppLogger.info('Splash: Routing to: ${nextScreen.runtimeType}');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.location_city,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Sidama Way Go',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Smart City Platform',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
