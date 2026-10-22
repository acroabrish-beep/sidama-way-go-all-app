import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'register_screen.dart';
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
import 'forgot_password_screen.dart';
import '../core/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() => _errorMessage = '');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final user = authProvider.userModel;
      if (user != null) {
        if (!context.mounted) return;
        _navigateByRole(user.role);
      } else {
        setState(() => _errorMessage = 'Authentication profile synchronization failed.');
      }
    } catch (e) {
      AppLogger.error('Login screen error', error: e);
      setState(
        () => _errorMessage = e.toString().contains('Exception:')
            ? e.toString().split('Exception:').last
            : 'Login failed. Please check your internet and credentials.',
      );
    }
  }

  @visibleForTesting
  void navigateByRole(UserRole role) {
    _navigateByRole(role);
  }

  void _navigateByRole(UserRole role) {
    Widget nextScreen;
    AppLogger.info('Navigating by role: ${role.name}');
    
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
    
    AppLogger.info('Routing to dashboard: ${nextScreen.runtimeType}');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.location_city,
                        size: 80,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sidama Way Go',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const Text(
                      'Smart City Platform',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
