import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/hotel_tourism_models.dart';

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
  final hotelScreen = read('lib/screens/hotel_screen.dart');
  final hotelDashboard = read('lib/screens/hotel_dashboard.dart');
  final tourismHome = read('lib/screens/tourism/tourism_home_screen.dart');
  final tourismDashboard = read('lib/screens/tourism_dashboard.dart');
  final tourismDashboardScreen =
      read('lib/screens/tourism/tourism_dashboard_screen.dart');
  final sitesScreen = read('lib/screens/tourism/tourist_sites_screen.dart');
  final service = read('lib/services/api/tourism_api_service.dart');

  group('Phase 2 screens use Supabase directly', () {
    test('requested screens no longer reference Firestore', () {
      for (final source in const [
        'lib/screens/hotel_screen.dart',
        'lib/screens/hotel_dashboard.dart',
        'lib/screens/tourism_dashboard.dart',
        'lib/screens/tourism/tourism_home_screen.dart',
        'lib/screens/tourism/tourism_dashboard_screen.dart',
        'lib/screens/tourism/tourist_sites_screen.dart',
      ]) {
        final content = read(source);
        expect(content.contains('FirebaseFirestore'), isFalse, reason: source);
        expect(content.contains('cloud_firestore'), isFalse, reason: source);
        expect(content.contains('StreamBuilder'), isFalse, reason: source);
        expect(content.contains('CityOSCollection'), isFalse, reason: source);
      }
    });

    test('tourism home loads live data without hardcoded counts', () {
      expect(tourismHome.contains('getTouristSites()'), isTrue);
      expect(tourismHome.contains('getHotels()'), isTrue);
      expect(tourismHome.contains('_seedInitialData'), isFalse);
      expect(tourismHome.contains('8 Sites'), isFalse);
      expect(tourismHome.contains('12 Guides'), isFalse);
      expect(tourismHome.contains('6 Packages'), isFalse);
      expect(tourismHome.contains('3 Events'), isFalse);
      expect(tourismHome.contains('.from('), isFalse);
    });

    test('tourism dashboards show live tabs and explicit gaps', () {
      for (final source in [tourismDashboard, tourismDashboardScreen]) {
        expect(source.contains('TourismOverviewTab'), isTrue);
        expect(source.contains('TourismHotelsOverview'), isTrue);
        expect(source.contains('Phase2NotMigratedPanel'), isTrue);
        expect(source.contains('AIInsightsCard'), isFalse);
        expect(source.contains('CRUDListScreen'), isFalse);
        expect(source.contains('FlSpot'), isFalse);
        expect(source.contains('BarChartGroupData'), isFalse);
      }
      expect(
        tourismDashboard.contains('TouristSitesScreen(embedded: true)'),
        isTrue,
      );
      expect(
        tourismDashboardScreen.contains('TouristSitesScreen(embedded: true)'),
        isTrue,
      );
    });

    test('hotel dashboard reviews reservations and manages hotels/rooms', () {
      expect(hotelDashboard.contains('getHotels()'), isTrue);
      expect(hotelDashboard.contains('getReservations()'), isTrue);
      expect(hotelDashboard.contains('updateReservationStatus('), isTrue);
      expect(hotelDashboard.contains('createHotel('), isTrue);
      expect(hotelDashboard.contains('createRoom('), isTrue);
      expect(hotelDashboard.contains("'CONFIRM'"), isTrue);
      expect(hotelDashboard.contains("'REJECT'"), isTrue);
    });

    test('hotel screen books a real room with dates and guests', () {
      expect(hotelScreen.contains('getHotels()'), isTrue);
      expect(hotelScreen.contains('createReservation('), isTrue);
      expect(hotelScreen.contains('showDatePicker'), isTrue);
      expect(hotelScreen.contains('bookingCode'), isTrue);
      expect(hotelScreen.contains('RESERVE ROOM'), isTrue);
      expect(hotelScreen.contains('availableRooms'), isTrue);
    });

    test('tourism sites screen uses live categories and writes', () {
      expect(
        sitesScreen.contains('TourismApiService.tourismCategories'),
        isTrue,
      );
      expect(sitesScreen.contains('createTouristSite('), isTrue);
      expect(sitesScreen.contains('deleteTouristSite('), isTrue);
      expect(sitesScreen.contains('tour_reviews'), isFalse);
      expect(sitesScreen.contains('isActive'), isFalse);
    });
  });

  group('tourism service queries and writes', () {
    test('reads through the location view and live tables', () {
      for (final table in const [
        'tourist_sites_with_location',
        'tourist_sites',
        'hotels',
        'hotel_rooms',
        'hotel_reservations',
      ]) {
        expect(service.contains("'$table'"), isTrue, reason: table);
      }
      expect(service.contains('Supabase.instance.client'), isTrue);
      expect(service.contains('BaseApiService('), isFalse);
    });

    test('site writes send an EWKT point instead of selecting geography', () {
      expect(service.contains('SRID=4326;POINT('), isTrue);
      expect(service.contains("'location'"), isTrue);
    });

    test('hotel reads never select ownership UIDs', () {
      final block = section(
        service,
        'static const _hotelColumns =',
        'static const _roomColumns =',
      );
      expect(block.contains('owner_firebase_uid'), isFalse);
      expect(block.contains('name'), isTrue);
      expect(block.contains('star_rating'), isTrue);
    });

    test('reservation insert sends only client-granted columns', () {
      final method = section(
        service,
        'Future<HotelReservationModel> createReservation(',
        'Future<HotelReservationModel> updateReservationStatus(',
      );
      final insert = section(method, '.insert({', '})');
      for (final column in const [
        'hotel_id',
        'room_id',
        'guest_name',
        'guest_phone',
        'check_in',
        'check_out',
        'guests',
      ]) {
        expect(insert.contains("'$column'"), isTrue, reason: column);
      }
      for (final column in const [
        'guest_firebase_uid',
        'booking_code',
        'hotel_name',
        'room_number',
        'room_type',
        'total_amount',
        'currency',
        'status',
        'decided_at',
        'decided_by_firebase_uid',
      ]) {
        expect(insert.contains("'$column'"), isFalse, reason: column);
      }
    });

    test('decision update changes only status and guards pending rows', () {
      final method = section(
        service,
        'Future<HotelReservationModel> updateReservationStatus(',
        'List<TourismSiteModel> _mapSites(',
      );
      final update = section(method, '.update({', '})');
      expect(update.contains("'status'"), isTrue);
      expect(update.contains('decided_at'), isFalse);
      expect(update.contains('decided_by_firebase_uid'), isFalse);
      expect(method.contains(".eq('status', 'pending')"), isTrue);
    });

    test('reservation reads exclude guest and decision UIDs', () {
      final block = section(
        service,
        'static const _reservationColumns =',
        'static const tourismCategories',
      );
      expect(block.contains('guest_firebase_uid'), isFalse);
      expect(block.contains('decided_by_firebase_uid'), isFalse);
      expect(block.contains('guest_name'), isTrue);
    });
  });

  group('hotel and tourism models parse live rows', () {
    test('hotel parses embedded rooms and computes availability', () {
      final hotel = HotelModel.fromRow({
        'id': 'h1',
        'name': 'Hotel One',
        'city': 'Hawassa',
        'address': 'Lake Road',
        'star_rating': 4,
        'status': 'published',
        'hotel_rooms': [
          {
            'id': 'r1',
            'hotel_id': 'h1',
            'room_number': '101',
            'room_type': 'Double',
            'capacity': 2,
            'nightly_rate': 1800,
            'currency': 'ETB',
            'status': 'available',
          },
          {
            'id': 'r2',
            'hotel_id': 'h1',
            'room_number': '102',
            'room_type': 'Suite',
            'capacity': 3,
            'nightly_rate': 2500,
            'currency': 'ETB',
            'status': 'maintenance',
          },
        ],
      });

      expect(hotel.rooms.length, 2);
      expect(hotel.availableRooms.length, 1);
      expect(hotel.lowestAvailableRate, 1800);
      expect(hotel.locationLabel, 'Lake Road, Hawassa');
      expect(hotel.ratingLabel, '4 star');
      expect(hotel.rooms.first.rateLabel, '1,800 ETB');
    });

    test('hotel tolerates a missing embedded room list', () {
      final hotel = HotelModel.fromRow({'id': 'h1', 'name': 'Hotel One'});
      expect(hotel.rooms, isEmpty);
      expect(hotel.availableRooms, isEmpty);
      expect(hotel.lowestAvailableRate, isNull);
      expect(hotel.locationLabel, 'Location not listed');
    });

    test('reservation parses dates, nights, and status', () {
      final reservation = HotelReservationModel.fromRow({
        'id': 'res1',
        'booking_code': 'SWG-ABC123',
        'hotel_id': 'h1',
        'room_id': 'r1',
        'hotel_name': 'Hotel One',
        'room_number': '101',
        'room_type': 'Double',
        'guest_name': 'Guest One',
        'guest_phone': '0911000000',
        'check_in': '2026-11-01',
        'check_out': '2026-11-03',
        'guests': 2,
        'total_amount': 3600,
        'currency': 'ETB',
        'status': 'pending',
      });

      expect(reservation.nights, 2);
      expect(reservation.isPending, isTrue);
      expect(reservation.statusLabel, 'Pending');
      expect(reservation.totalLabel, '3,600 ETB');
      expect(formatBookingDate(reservation.checkIn), 'Nov 1, 2026');
    });

    test('tourist site formats category and fees from live values', () {
      final paid = TourismSiteModel.fromRow({
        'id': 's1',
        'name': 'Lake Hawassa',
        'category': 'NATURAL',
        'latitude': 7.05,
        'longitude': 38.48,
        'entrance_fee': 50,
        'rating': 4.5,
        'reviews_count': 12,
      });
      final free = TourismSiteModel.fromRow({
        'id': 's2',
        'name': 'City Park',
        'category': 'entertainment',
        'entrance_fee': 0,
      });

      expect(paid.category, 'natural');
      expect(paid.categoryLabel, 'Natural');
      expect(paid.entryFeeLabel, '50 ETB');
      expect(paid.coordinatesLabel, '7.05000, 38.48000');
      expect(free.entryFeeLabel, 'Free');
      expect(free.categoryLabel, 'Entertainment');
    });

    test('rows missing required ids or names are rejected', () {
      expect(
        () => HotelModel.fromRow({'name': 'No id'}),
        throwsFormatException,
      );
      expect(
        () => HotelRoomModel.fromRow({'hotel_id': 'h1'}),
        throwsFormatException,
      );
      expect(
        () => HotelReservationModel.fromRow({'id': 'r1'}),
        throwsFormatException,
      );
      expect(
        () => TourismSiteModel.fromRow({'id': 's1'}),
        throwsFormatException,
      );
    });

    test('formatAmount groups thousands and keeps cents', () {
      expect(formatAmount(3600), '3,600');
      expect(formatAmount(1800.5), '1,800.50');
      expect(formatAmount(null), '0');
    });
  });
}
