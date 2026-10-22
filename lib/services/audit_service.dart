import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_os_models.dart';

class AuditService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> logAction(String action, {String? details}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection(CityOSCollection.users).doc(user?.uid).get();
    final role = userData.data()?['role'] ?? 'Unknown';

    await _db.collection('audit_logs').add({
      'action': action,
      'userId': user?.uid,
      'userEmail': user?.email,
      'userName': userData.data()?['fullName'] ?? 'System',
      'userRole': role,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
