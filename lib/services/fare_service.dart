import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_models.dart';
import '../models/taxi_models.dart';

class FareService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SMART FARE ENGINE ---

  Future<double> calculateFare({
    required VehicleType vehicleType,
    required double distanceKm,
    required double durationMinutes,
    String? category, // student, elderly, disabled
    bool isHoliday = false,
    bool isNight = false,
  }) async {
    // 1. Fetch Fare Rule for Vehicle Type
    final ruleSnap = await _db.collection('pricing_rules')
        .where('vehicleType', isEqualTo: vehicleType.name)
        .limit(1)
        .get();

    FareRule rule;
    if (ruleSnap.docs.isNotEmpty) {
      rule = FareRule.fromFirestore(ruleSnap.docs.first);
    } else {
      // Default fallback pricing
      rule = FareRule(
        ruleId: 'default',
        vehicleType: vehicleType,
        baseFare: 15.0,
        perKmRate: 12.0,
        perMinuteRate: 1.5,
      );
    }

    // 2. Base Calculation
    double total = rule.baseFare + (distanceKm * rule.perKmRate) + (durationMinutes * rule.perMinuteRate);

    // 3. Apply Multipliers
    double multiplier = rule.surgeMultiplier;
    if (isNight) multiplier *= 1.5;
    if (isHoliday) multiplier *= 1.2;

    total *= multiplier;

    // 4. Apply Category Discounts
    if (category != null && rule.categoryDiscounts.containsKey(category)) {
      total *= (1 - rule.categoryDiscounts[category]!);
    }

    return total;
  }

  Future<void> updateFareRule(FareRule rule) async {
    await _db.collection('pricing_rules').doc(rule.ruleId.isEmpty ? null : rule.ruleId).set({
      'vehicleType': rule.vehicleType.name,
      'baseFare': rule.baseFare,
      'perKmRate': rule.perKmRate,
      'perMinuteRate': rule.perMinuteRate,
      'surgeMultiplier': rule.surgeMultiplier,
      'categoryDiscounts': rule.categoryDiscounts,
      'isNightService': rule.isNightService,
      'isHoliday': rule.isHoliday,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
