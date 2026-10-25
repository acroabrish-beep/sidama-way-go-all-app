import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/emergency_sos_models.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  final citizenScreen = read('lib/screens/emergency_screen.dart');
  final staffDashboard = read('lib/screens/emergency_dashboard.dart');
  final service = read('lib/services/api/emergency_api_service.dart');

  group('Phase 3 screens use Supabase directly', () {
    test('emergency screens no longer reference Firestore', () {
      for (final source in [citizenScreen, staffDashboard]) {
        expect(source.contains('cloud_firestore'), isFalse);
        expect(source.contains('FirebaseFirestore'), isFalse);
        expect(source.contains('sos_requests'), isFalse);
        expect(source.contains('StreamBuilder'), isFalse);
      }
      expect(staffDashboard.contains('CRUDListScreen'), isFalse);
    });

    test('citizen SOS screen creates and polls a Supabase request', () {
      expect(citizenScreen.contains('EmergencyApiService'), isTrue);
      expect(citizenScreen.contains('createRequest('), isTrue);
      expect(citizenScreen.contains('findActiveRequest('), isTrue);
      expect(citizenScreen.contains('getRequest('), isTrue);
      expect(citizenScreen.contains('Geolocator.getCurrentPosition'), isTrue);
    });

    test('staff dashboard advances incident status', () {
      expect(staffDashboard.contains('listIncidents('), isTrue);
      expect(staffDashboard.contains('listActiveIncidents('), isTrue);
      expect(staffDashboard.contains('updateStatus('), isTrue);
      expect(staffDashboard.contains("'ACKNOWLEDGE'"), isTrue);
      expect(staffDashboard.contains("'DISPATCH'"), isTrue);
      expect(staffDashboard.contains("'RESOLVE'"), isTrue);
    });
  });

  group('emergency service reads and writes Supabase tables', () {
    test('uses emergency_incidents and Phase 3 columns only', () {
      expect(service.contains("'emergency_incidents'"), isTrue);
      expect(service.contains('requester_firebase_uid'), isTrue);
      expect(service.contains('emergency_type'), isTrue);
      expect(service.contains('assignee_firebase_uid'), isTrue);
      expect(service.contains('resolved_at'), isTrue);
      expect(service.contains('Supabase.instance.client'), isTrue);
      expect(service.contains('BaseApiService('), isFalse);
      expect(service.contains('http.'), isFalse);
    });
  });

  group('EmergencyIncidentModel', () {
    test('maps a Phase 3 row and labels its state', () {
      final incident = EmergencyIncidentModel.fromRow({
        'id': '0d0f0f0f-0000-4000-8000-000000000001',
        'incident_code': 'INC-20261025120000',
        'requester_firebase_uid': 'firebase-citizen',
        'emergency_type': 'police',
        'priority': 'high',
        'status': 'acknowledged',
        'description': 'Police assistance is requested.',
        'latitude': 7.05,
        'longitude': 38.47,
        'assignee_firebase_uid': 'firebase-admin',
        'created_at': '2026-10-25T09:00:00Z',
        'updated_at': '2026-10-25T09:01:00Z',
        'resolved_at': null,
      });

      expect(incident.typeLabel, 'Police');
      expect(incident.statusLabel, 'Acknowledged');
      expect(incident.priorityLabel, 'High');
      expect(incident.isActive, isTrue);
      expect(incident.isResolved, isFalse);
      expect(incident.coordinatesLabel, '7.05000, 38.47000');
      expect(incident.assigneeFirebaseUid, 'firebase-admin');
    });

    test('falls back to the legacy incident_type column', () {
      final incident = EmergencyIncidentModel.fromRow({
        'id': '0d0f0f0f-0000-4000-8000-000000000002',
        'incident_type': 'medical',
        'severity': 'critical',
        'status': 'resolved',
        'resolved_at': '2026-10-25T09:30:00Z',
      });

      expect(incident.emergencyType, 'medical');
      expect(incident.typeLabel, 'Medical');
      expect(incident.priority, 'critical');
      expect(incident.isResolved, isTrue);
      expect(incident.isActive, isFalse);
    });

    test('rejects a row without an id', () {
      expect(
        () => EmergencyIncidentModel.fromRow({'status': 'reported'}),
        throwsFormatException,
      );
    });
  });
}
