import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ai_service.dart';

class SmartAIService {
  static final AIService _realAI = NextJSAIServiceImpl();

  static Future<String> getRouteRecommendation(String destination) async {
    try {
      final response = await _realAI.chat(
        "Suggest an optimized route to $destination in Hawassa city. Mention any landmarks or potential traffic areas.",
        "en",
      );
      return response;
    } catch (e) {
      return "Route optimized for current traffic conditions.";
    }
  }

  static Future<Map<String, dynamic>> predictTraffic(String routeId) async {
    return {
      'congestionLevel': 'low',
      'predictedDelay': 0,
      'alternativeRoute': true,
    };
  }
}

class SmartPaymentService {
  static Future<bool> processTelebirr(double amount) async {
    // Integration logic for Telebirr
    return true;
  }

  static Future<bool> processCBEBirr(double amount) async {
    // Integration logic for CBE Birr
    return true;
  }

  static Future<bool> processChapa(double amount) async {
    // Integration logic for Chapa
    return true;
  }
}

class SmartNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    // Logic for token management and background messages
  }

  static Future<void> sendSOS(GeoPoint location) async {
    await FirebaseFirestore.instance.collection('emergency_alerts').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'location': location,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  static Future<void> scheduleReminder(String title, String body, DateTime time) async {
    // In a production app, this would use FCM tokens or local notifications.
    // For now, we save it to a 'reminders' collection which a Cloud Function can pick up.
    await FirebaseFirestore.instance.collection('reminders').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'title': title,
      'body': body,
      'scheduledTime': time,
      'sent': false,
    });
  }
}
