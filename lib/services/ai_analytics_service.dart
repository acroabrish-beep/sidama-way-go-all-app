import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import 'api/ai_api_service.dart';

class AIAnalyticsService {
  // Read ALL real data from Firebase
  static Future<Map<String, dynamic>> _readAllFirebaseData() async {
    final db = FirebaseFirestore.instance;
    final Map<String, dynamic> data = {};

    try {
      // Core Subsystems Snapshot
      final fleet = await db.collection('vehicles').get();
      final workforce = await db.collection('drivers').get();
      final hubs = await db.collection('taxi_stations').get();
      final emergencies = await db.collection('emergency_incidents').get();
      final payments = await db.collection('payments').get();

      data['fleetSize'] = fleet.docs.length;
      data['activeVehicles'] = fleet.docs
          .where(
            (d) => d.get('status') == 'moving' || d.get('status') == 'busy',
          )
          .length;

      data['onlineWorkforce'] = workforce.docs
          .where((d) => d.get('online') == true)
          .length;
      data['unapprovedWorkforce'] = workforce.docs
          .where((d) => d.get('governmentApproval') != 'approved')
          .length;

      data['stationCongestion'] = hubs.docs
          .where((d) => (d.get('occupancyPercentage') ?? 0) > 80)
          .length;

      data['criticalIncidents'] = emergencies.docs
          .where(
            (d) =>
                d.get('priority') == 'critical' &&
                d.get('status') != 'resolved',
          )
          .length;

      data['revenueToday'] = payments.docs
          .where((d) {
            final ts = (d.get('timestamp') as Timestamp).toDate();
            final now = DateTime.now();
            return ts.year == now.year &&
                ts.month == now.month &&
                ts.day == now.day;
          })
          .fold<double>(
            0.0,
            (sumVal, d) => sumVal + (d.get('amount') as num).toDouble(),
          );

      // Hotels
      final hotels = await db.collection('hotel_reservations').get();
      data['totalHotelBookings'] = hotels.docs.length;
      data['hotelRevenue'] = hotels.docs.fold<double>(0, (sumVal, d) {
        final dData = d.data();
        return sumVal + ((dData['totalPrice'] as num?) ?? 0).toDouble();
      });
      data['pendingHotelBookings'] = hotels.docs.where((d) {
        final dData = d.data();
        return dData['status'] == 'pending';
      }).length;

      // Food
      final food = await db.collection('food_orders').get();
      data['totalFoodOrders'] = food.docs.length;
      data['foodRevenue'] = food.docs.fold<double>(0, (sumVal, d) {
        final dData = d.data();
        return sumVal + ((dData['totalPrice'] as num?) ?? 0).toDouble();
      });
      data['pendingFoodOrders'] = food.docs.where((d) {
        final dData = d.data();
        return dData['status'] == 'pending';
      }).length;

      // Pharmacy
      final pharmacy = await db.collection('medicine_orders').get();
      data['totalPharmacyOrders'] = pharmacy.docs.length;
      data['pharmacyRevenue'] = pharmacy.docs.fold<double>(0, (sumVal, d) {
        final dData = d.data();
        return sumVal + ((dData['totalPrice'] as num?) ?? 0).toDouble();
      });

      // Eco-Shine
      final eco = await db.collection('eco_shine_bookings').get();
      data['totalEcoShineBookings'] = eco.docs.length;
      data['ecoShineRevenue'] = eco.docs.fold<double>(0, (sumVal, d) {
        final dData = d.data();
        return sumVal + ((dData['price'] as num?) ?? 0).toDouble();
      });

      // Tourism
      final tourism = await db.collection('tourist_bookings').get();
      data['totalTouristBookings'] = tourism.docs.length;
      data['tourismRevenue'] = tourism.docs.fold<double>(0, (sumVal, d) {
        final dData = d.data();
        return sumVal + ((dData['totalPrice'] as num?) ?? 0).toDouble();
      });

      // Contract rides
      final contractRides = await db.collection('contract_rides').get();
      data['totalContractRides'] = contractRides.docs.length;

      // Drivers & Vehicles
      final drivers = await db.collection('drivers').get();
      data['totalDrivers'] = drivers.docs.length;
      data['activeDrivers'] = drivers.docs.where((d) {
        final dData = d.data();
        return dData['status'] == 'active';
      }).length;

      final vehicles = await db.collection('vehicles').get();
      data['totalVehicles'] = vehicles.docs.length;

      // Hospitals & Pharmacies
      final appointments = await db.collection('appointments').get();
      data['totalAppointments'] = appointments.docs.length;
      data['pendingAppointments'] = appointments.docs.where((d) {
        final dData = d.data();
        return dData['status'] == 'pending';
      }).length;

      // Total Revenue
      data['totalRevenue'] =
          ((data['busRevenue'] as double?) ?? 0) +
          ((data['hotelRevenue'] as double?) ?? 0) +
          ((data['foodRevenue'] as double?) ?? 0) +
          ((data['pharmacyRevenue'] as double?) ?? 0) +
          ((data['ecoShineRevenue'] as double?) ?? 0) +
          ((data['tourismRevenue'] as double?) ?? 0);

      // Users
      final users = await db.collection('users').get();
      data['totalUsers'] = users.docs.length;

      // Announcements
      final announcements = await db.collection('announcements').get();
      data['totalAnnouncements'] = announcements.docs.length;
      data['activeAnnouncements'] = announcements.docs.where((d) {
        final dData = d.data();
        return dData['isActive'] == true;
      }).length;
    } catch (e) {
      data['error'] = e.toString();
    }

    return data;
  }

  // Generate AI insights from Firebase data
  static Future<String> generateInsights({
    String dashboardContext = 'super_admin',
  }) async {
    final data = await _readAllFirebaseData();

    if (data['error'] != null) {
      throw Exception('Unable to read dashboard data: ${data['error']}');
    }

    final dataStr =
        '''
SIDAMA CityOS EXECUTIVE REPORT - ${DateTime.now().toLocal()}

TRANSPORTATION & FLEET:
- Fleet Size: ${data['fleetSize']}
- Active (Moving/Busy): ${data['activeVehicles']}
- Workforce Online: ${data['onlineWorkforce']}
- Compliance Alerts (Unapproved): ${data['unapprovedWorkforce']}

INFRASTRUCTURE & FLOW:
- Congested Hubs (>80%): ${data['stationCongestion']}
- Critical Emergency Incidents: ${data['criticalIncidents']}

FINANCIALS:
- Revenue Today: ${data['revenueToday']?.toStringAsFixed(0)} ETB

DASHBOARD: $dashboardContext
''';

    final prompt =
        '''
You are the Smart City AI Brain for the Sidama Region Government.
Analyze this live Digital Twin snapshot and provide executive operational guidance.

$dataStr

Provide a production-ready briefing:
1. 🛡️ PUBLIC SAFETY & EMERGENCY (Incidents, readiness, response)
2. 🚦 TRANSIT OPTIMIZATION (Fleet utilization, hub congestion, redistribution needs)
3. 🏛️ COMPLIANCE & GOVERNANCE (Workforce status, unapproved assets)
4. 💰 FINANCIAL INTEGRITY (Revenue performance)
5. 🎯 TOP COMMANDER RECOMMENDATION (One primary actionable item for the Mayor)

Be decisive, use actual numbers, and keep it under 300 words.
''';

    // All AI calls go through the Next.js backend; the client holds no AI key.
    final api = AIApiService();
    try {
      return await api.sendMessage(message: prompt, language: 'en');
    } catch (e) {
      AppLogger.error('AI analytics request failed', error: e);
      rethrow;
    } finally {
      api.dispose();
    }
  }

}
