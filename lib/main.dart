import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/tracking_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/city_platform_provider.dart';
import 'providers/extended_platform_provider.dart';
import 'providers/mobility_provider.dart';
import 'providers/smart_city_provider.dart';
import 'providers/location_provider.dart';
import 'providers/map_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/language_provider.dart';
import 'providers/taxi_demo_provider.dart';

import 'services/boot_service.dart';
import 'core/error/error_handler.dart';
import 'services/smart_services.dart';
import 'core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'verify.dart';
import 'core/config/env_config.dart';
import 'config/app_config.dart';
import 'services/api/supabase_client.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Error Handling early
  ErrorHandler.init();

  try {
    // 3. Log current configuration
    AppConfig.logConfig();
    EnvConfig.verifyConfig();

    // 4. Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Enable Offline Persistence for Smart City Digital Twin
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      AppLogger.info('Firebase initialized with persistence');
    } catch (e) {
      AppLogger.error('Firebase initialization failed', error: e);
      // Continue booting - some features might be disabled
    }

    // 5. Initialize Supabase
    try {
      await SupabaseClient.initialize();
      AppLogger.info('Supabase initialized successfully');
    } catch (e) {
      AppLogger.error('Supabase initialization failed', error: e);
      // Continue booting - some features might be disabled
    }

    // 6. Initialize Notifications
    try {
      await SmartNotificationService.initialize();
    } catch (e) {
      AppLogger.warning('Notification initialization failed: $e');
    }

    // 7. Initialize City OS Data
    try {
      await BootService.initializeCity();
    } catch (e) {
      AppLogger.error('City Boot failed', error: e);
    }

    // 8. Run the startup audit in debug builds only.
    if (kDebugMode) {
      SystemVerifier.runFullAudit().catchError((e) => AppLogger.warning('Audit failed: $e'));
    }

  } catch (globalError, stackTrace) {
    AppLogger.error('Critical startup error', error: globalError, stackTrace: stackTrace);
  }

  // 9. Always run the app to prevent white screen
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => MobilityProvider()),
        ChangeNotifierProvider(create: (_) => SmartCityProvider()),
        ChangeNotifierProvider(create: (_) => CityPlatformProvider()),
        ChangeNotifierProvider(create: (_) => ExtendedPlatformProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => TaxiDemoProvider()),
      ],
      child: const SmartMobilityApp(),
    ),
  );
}

class SmartMobilityApp extends StatelessWidget {
  const SmartMobilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Mobility Hawassa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        primaryColor: const Color(0xFF2E7D32),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
