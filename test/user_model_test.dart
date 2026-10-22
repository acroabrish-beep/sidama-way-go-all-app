import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/user_model.dart';

void main() {
  group('UserModel.fromMap Hardening', () {
    test('should parse camelCase (Firestore) format correctly', () {
      final map = {
        'fullName': 'John Doe',
        'email': 'john@example.com',
        'role': 'superAdmin',
        'isApproved': true,
        'walletBalance': 50.5,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final user = UserModel.fromMap(map, 'uid123');

      expect(user.fullName, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.role, UserRole.superAdmin);
      expect(user.isApproved, true);
      expect(user.walletBalance, 50.5);
    });

    test('should parse snake_case (Supabase/API) format correctly', () {
      final map = {
        'full_name': 'Jane Smith',
        'email': 'jane@example.com',
        'role': 'taxi_admin',
        'is_approved': false,
        'wallet_balance': 100.0,
        'created_at': DateTime(2026, 2, 2).toIso8601String(),
      };

      final user = UserModel.fromMap(map, 'uid456');

      expect(user.fullName, 'Jane Smith');
      expect(user.email, 'jane@example.com');
      expect(user.role, UserRole.taxiAdmin);
      expect(user.isApproved, false);
      expect(user.walletBalance, 100.0);
    });

    test('should handle special role mappings correctly', () {
      final map = {
        'role': 'healthcare_admin',
      };

      final user = UserModel.fromMap(map, 'uid789');
      expect(user.role, UserRole.healthAdmin);
    });
  });

  group('UserModel business role', () {
    test('normalizeRole maps businessAdmin variants to canonical business', () {
      expect(UserModel.normalizeRole('businessAdmin'), 'business');
      expect(UserModel.normalizeRole('business_admin'), 'business');
      expect(UserModel.normalizeRole('Business Admin'), 'business');
      expect(UserModel.normalizeRole('business'), 'business');
    });

    test('parseUserRole maps business to UserRole.businessAdmin', () {
      expect(UserModel.parseUserRole('business'), UserRole.businessAdmin);
      expect(UserModel.parseUserRole('businessAdmin'), UserRole.businessAdmin);
      expect(UserModel.parseUserRole('BUSINESS_ADMIN'), UserRole.businessAdmin);
    });

    test('fromMap parses a business-admin user from Firestore/API shapes', () {
      expect(
        UserModel.fromMap({'role': 'businessAdmin'}, 'uid_biz').role,
        UserRole.businessAdmin,
      );
      expect(
        UserModel.fromMap({'role': 'business_admin'}, 'uid_biz').role,
        UserRole.businessAdmin,
      );
      expect(
        UserModel.fromMap({'userType': 'businessAdmin'}, 'uid_biz').role,
        UserRole.businessAdmin,
      );
    });

    test('toMap serializes businessAdmin as canonical business and round-trips',
        () {
      final user = UserModel(
        uid: 'uid_biz',
        fullName: 'Business Admin',
        email: 'business@example.com',
        phone: '0912345678',
        role: UserRole.businessAdmin,
        department: 'Business',
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime(2026, 1, 2),
      );

      final map = user.toMap();
      expect(map['role'], 'business');

      final reparsed = UserModel.fromMap(map, 'uid_biz');
      expect(reparsed.role, UserRole.businessAdmin);
    });
  });

  group('normalizeRole regressions', () {
    test('null, empty, whitespace, and citizen stay citizen', () {
      expect(UserModel.normalizeRole(null), 'citizen');
      expect(UserModel.normalizeRole(''), 'citizen');
      expect(UserModel.normalizeRole('   '), 'citizen');
      expect(UserModel.normalizeRole('citizen'), 'citizen');
    });

    test('parseUserRole falls back to citizen for null/empty/unknown', () {
      expect(UserModel.parseUserRole(null), UserRole.citizen);
      expect(UserModel.parseUserRole(''), UserRole.citizen);
      expect(UserModel.parseUserRole('totally_unknown_role'), UserRole.citizen);
    });
  });

  group('UserRole round-trip (all values)', () {
    // Canonical short codes the model stores for each enum, derived from the
    // actual normalizeRole()/parseUserRole() control flow (not assumed).
    const expectedCanonical = <UserRole, String>{
      UserRole.superAdmin: 'admin',
      UserRole.oldTerminalAdmin: 'old_terminal',
      UserRole.newTerminalAdmin: 'new_terminal',
      UserRole.taxiAdmin: 'taxi',
      UserRole.tourismAdmin: 'tourism',
      UserRole.hotelAdmin: 'hotel',
      UserRole.healthAdmin: 'health',
      UserRole.pharmacyAdmin: 'pharmacy',
      UserRole.emergencyAdmin: 'emergency',
      UserRole.churchAdmin: 'church',
      UserRole.businessAdmin: 'business',
      UserRole.governmentFleetAdmin: 'government_fleet',
      UserRole.taxiDriver: 'taxi_driver',
      UserRole.citizen: 'citizen',
    };

    test('every UserRole has an expected canonical code (coverage guard)', () {
      for (final role in UserRole.values) {
        expect(
          expectedCanonical.containsKey(role),
          isTrue,
          reason: 'No expected canonical code listed for ${role.name}',
        );
      }
      expect(expectedCanonical.length, UserRole.values.length);
    });

    test('normalizeRole(role.name) equals the expected canonical code', () {
      for (final role in UserRole.values) {
        expect(
          UserModel.normalizeRole(role.name),
          expectedCanonical[role],
          reason: 'Canonical code mismatch for ${role.name}',
        );
      }
    });

    test('parseUserRole(normalizeRole(role.name)) == role', () {
      for (final role in UserRole.values) {
        expect(
          UserModel.parseUserRole(UserModel.normalizeRole(role.name)),
          role,
          reason: 'Round-trip failed for ${role.name}',
        );
      }
    });
  });
}
