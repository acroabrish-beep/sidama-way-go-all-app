import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/taxi_models.dart';

void main() {
  group('Workforce Engine Phase 4 Verification', () {
    test('WorkforceMember Model Mapping', () {
      final member = WorkforceMember(
        workerId: 'W-001',
        fullName: 'Abebe Bikila',
        role: WorkforceRole.busDriver,
        phone: '0911223344',
        employeeNumber: 'EMP-777',
        licenseExpiry: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(member.role, WorkforceRole.busDriver);
      expect(member.employeeNumber, 'EMP-777');
      print('PASS: WorkforceMember model mapping verified');
    });

    test('Lifecycle Status Logic', () {
      final status = WorkforceLifecycleStatus.medicalHold;
      expect(status.toString().contains('medicalHold'), true);
      print('PASS: Lifecycle status enum verified');
    });

    test('Backward Compatibility (TaxiDriver Typedef)', () {
      final TaxiDriver legacyDriver = WorkforceMember(
        workerId: 'D-001',
        fullName: 'Legacy Driver',
        role: WorkforceRole.taxiDriver,
        phone: '0900000000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(legacyDriver.fullName, 'Legacy Driver');
      print('PASS: Backward compatibility via typedef confirmed');
    });

    test('Shift and Attendance Modeling', () {
      final shift = ShiftType.night;
      expect(shift.name, 'night');
      print('PASS: Shift management model confirmed');
    });
  });
}
