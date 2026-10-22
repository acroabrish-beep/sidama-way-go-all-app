import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/mobility_models.dart';
import '../models/city_os_models.dart';
import '../services/smart_city_service.dart';

class SmartCityProvider with ChangeNotifier {
  final SmartCityService _service = SmartCityService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadUserData() async {
    _currentUser = await _service.getCurrentUser();
    notifyListeners();
  }

  // Intercity Bus State
  List<BusVehicle> _availableBuses = [];
  List<BusVehicle> get availableBuses => _availableBuses;

  void fetchBuses(String terminalId) {
    // In a real app, this would be a stream listener
    FirebaseFirestore.instance.collection('buses')
      .where('terminalId', isEqualTo: terminalId)
      .where('status', isEqualTo: 'ready')
      .snapshots()
      .listen((snap) {
        _availableBuses = snap.docs.map((doc) => BusVehicle.fromFirestore(doc)).toList();
        notifyListeners();
      });
  }

  Future<void> bookTicket(Ticket ticket) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.bookBusTicket(ticket);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Emergency State
  Future<void> triggerSOS(String type, GeoPoint location, String userName) async {
    await _service.requestEmergency(type, location, userName);
  }
}
