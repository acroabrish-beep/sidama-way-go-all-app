import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

String section(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  if (startIndex < 0 || endIndex < 0) {
    throw StateError('Could not locate section between "$start" and "$end"');
  }
  return source.substring(startIndex, endIndex);
}

void main() {
  final source = read(
    'lib/services/api/citizen_reporting_api_service.dart',
  );

  group('citizen reporting uses Supabase directly', () {
    test('no longer calls the legacy API route', () {
      expect(source.contains('/api/citizen-reporting'), isFalse);
      expect(source.contains('BaseApiService('), isFalse);
    });

    test('queries the RLS-protected table', () {
      expect(
        source.contains("static const _table = 'citizen_reports';"),
        isTrue,
      );
      expect(RegExp(r'\.from\(_table\)').allMatches(source).length, 4);
    });

    test('create sends only the client-granted insert columns', () {
      final block = section(
        source,
        'Future<CitizenReport> createReport',
        'Future<ReportsPage> getMyReports',
      );
      const granted = [
        'reporter_firebase_uid',
        'category',
        'description',
        'photo_url',
        'latitude',
        'longitude',
      ];
      for (final column in granted) {
        expect(block.contains("'$column'"), isTrue, reason: column);
      }
      const serverOwned = [
        'status',
        'ai_status',
        'ai_category',
        'ai_urgency',
        'final_category',
        'final_urgency',
        'assigned_at',
        'resolved_at',
        'created_at',
        'updated_at',
      ];
      for (final column in serverOwned) {
        expect(block.contains("'$column'"), isFalse, reason: column);
      }
    });

    test('staff update sends only the granted update columns', () {
      final block = section(
        source,
        'Future<CitizenReport> updateReport',
        '\n  }\n}',
      );
      const granted = [
        'status',
        'final_category',
        'final_urgency',
        'assigned_at',
        'resolved_at',
      ];
      for (final column in granted) {
        expect(block.contains("'$column'"), isTrue, reason: column);
      }
      expect(block.contains("'reporter_firebase_uid'"), isFalse);
      expect(block.contains("'ai_"), isFalse);
      expect(block.contains("'created_at'"), isFalse);
      expect(block.contains("'updated_at'"), isFalse);
    });

    test('never embeds privileged credentials', () {
      expect(source.toLowerCase().contains('service_role'), isFalse);
      expect(source.contains('GEMINI'), isFalse);
      expect(source.contains('FIREBASE_SERVICE_ACCOUNT'), isFalse);
    });
  });
}
