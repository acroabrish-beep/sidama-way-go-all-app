import 'firestore_service.dart';
import 'package:flutter/foundation.dart';

class BootService {
  static Future<void> initializeCity() async {
    // Demo seeding is debug-only; a release build must never seed data.
    if (!kDebugMode) return;

    final fs = FirestoreService();
    await fs.ensureInitialData();
  }
}
