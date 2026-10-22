import 'package:flutter/material.dart';
import '../models/mobility_models.dart';
import '../models/taxi_models.dart';
import '../models/city_os_models.dart';
import '../services/mobility_service.dart';

class MobilityProvider with ChangeNotifier {
  final MobilityService _service = MobilityService();

  List<BusRoute> _busRoutes = [];
  List<TaxiRoute> _taxiRoutes = [];
  bool _isLoading = false;

  List<BusRoute> get busRoutes => _busRoutes;
  List<TaxiRoute> get taxiRoutes => _taxiRoutes;
  bool get isLoading => _isLoading;

  Future<void> fetchBusRoutes(String terminalId) async {
    _isLoading = true;
    notifyListeners();
    _busRoutes = await _service.getBusRoutes(terminalId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTaxiRoutes() async {
    _isLoading = true;
    notifyListeners();
    _taxiRoutes = await _service.getTaxiRoutes();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> bookBusTicket(Ticket ticket) async {
    return await _service.bookTicket(ticket);
  }
}
