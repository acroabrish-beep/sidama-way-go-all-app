import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/city_os_models.dart';
import 'services/ai_service.dart';
import 'core/utils/logger.dart';

class SystemVerifier {
  static Future<void> runFullAudit() async {
    AppLogger.info('--- STARTING PRODUCTION AUDIT ---');

    // 1. Firebase Connectivity
    try {
      final db = FirebaseFirestore.instance;
      await db.collection(CityOSCollection.users).limit(1).get();
      AppLogger.info('✓ Firebase Firestore: Connected');
    } catch (e) {
      AppLogger.error('✗ Firebase Firestore: Failed', error: e);
    }

    // 2. Collection Validation
    final collections = [
      CityOSCollection.users,
      CityOSCollection.drivers,
      CityOSCollection.taxis,
      CityOSCollection.taxiStations,
      CityOSCollection.rideRequests,
      CityOSCollection.routes,
      CityOSCollection.announcements,
      CityOSCollection.tourismSites,
      CityOSCollection.hotels,
      CityOSCollection.hospitals,
      CityOSCollection.pharmacies,
      CityOSCollection.emergencyRequests,
      CityOSCollection.payments,
      CityOSCollection.analytics,
      CityOSCollection.auditLogs,
    ];

    for (var col in collections) {
      try {
        await FirebaseFirestore.instance.collection(col).limit(1).get();
        AppLogger.info('✓ Collection [$col]: Valid');
      } catch (e) {
        AppLogger.error('✗ Collection [$col]: Error', error: e);
      }
    }

    // 3. AI Assistant Pipeline
    try {
      // Test the production AI service (Next.js backend)
      final aiService = NextJSAIServiceImpl();
      
      // We don't provide a key in code anymore, it should be in the backend .env
      // Here we check if the backend reports it's missing or if the request fails.
      final testResponse = await aiService.chat('Test connection', 'en');
      
      if (testResponse.contains('I apologize, but the AI service is temporarily unavailable') || 
          testResponse.contains('ይቅርታ፣ የ AI አገልግሎት ለጊዜው አልተገኘም')) {
        
        // This response comes from _getFallbackResponse which is called on catch(e)
        // Usually means backend is down or network error
        AppLogger.error('✗ AI Service: Backend Unreachable or Connection Error');
      } else if (testResponse.contains('API key is missing') || 
                 testResponse.contains('API key not valid')) {
        AppLogger.warning('! AI Service: Not Configured - API key missing on backend');
      } else if (testResponse.contains('500') || 
                 testResponse.contains('Internal server error')) {
        AppLogger.error('✗ AI Service: Backend Error - HTTP 500');
      } else if (testResponse.isNotEmpty) {
        AppLogger.info('✓ AI Service (Next.js Backend): Functional');
      } else {
        AppLogger.warning('! AI Service: Empty response');
      }
    } catch (e) {
      AppLogger.error('✗ AI Pipeline: Failed', error: e);
    }

    AppLogger.info('--- AUDIT COMPLETE ---');
  }
}
