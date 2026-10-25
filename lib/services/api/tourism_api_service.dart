import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/hotel_tourism_models.dart';
import 'base_api_service.dart';

class TourismApiService {
  static const _sitesView = 'tourist_sites_with_location';
  static const _sitesTable = 'tourist_sites';
  static const _hotelsTable = 'hotels';
  static const _roomsTable = 'hotel_rooms';
  static const _reservationsTable = 'hotel_reservations';
  static const _timeout = Duration(seconds: 30);
  static const _listLimit = 200;

  static const _siteColumns =
      'id, name, description, category, latitude, longitude, address, '
      'opening_hours, website, phone, entrance_fee, rating, reviews_count, '
      'images_urls, verified, created_at, updated_at';
  static const _hotelColumns =
      'id, name, description, address, city, phone, latitude, longitude, '
      'star_rating, image_urls, status, created_at, updated_at';
  static const _roomColumns =
      'id, hotel_id, room_number, room_type, capacity, nightly_rate, '
      'currency, status';
  static const _reservationColumns =
      'id, booking_code, hotel_id, room_id, hotel_name, room_number, '
      'room_type, guest_name, guest_phone, check_in, check_out, guests, '
      'total_amount, currency, status, decided_at, created_at, updated_at';

  static const tourismCategories = [
    'historical',
    'natural',
    'cultural',
    'religious',
    'entertainment',
    'shopping',
    'dining',
  ];

  SupabaseClient get _client => Supabase.instance.client;

  String _requireUid(String action) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw ApiException(
        'Sign in to $action.',
        statusCode: 401,
        code: 'not_authenticated',
      );
    }
    return uid;
  }

  Future<List<TourismSiteModel>> getTouristSites() async {
    _requireUid('browse tourist sites');
    try {
      final rows = await _client
          .from(_sitesView)
          .select(_siteColumns)
          .order('name', ascending: true)
          .timeout(_timeout);
      return _mapSites(rows);
    } on PostgrestException catch (error) {
      throw _readFailure(error, 'tourist sites');
    } on TimeoutException {
      throw ApiException(
        'Loading tourist sites timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<void> createTouristSite({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    String? description,
    String? address,
    String? openingHours,
    String? phone,
    double? entranceFee,
  }) async {
    _requireUid('add a tourist site');
    final trimmedName = name.trim();
    final trimmedCategory = category.trim().toLowerCase();
    if (trimmedName.length < 2 || trimmedName.length > 160) {
      throw ApiException(
        'Enter a site name between 2 and 160 characters.',
        code: 'invalid_request',
      );
    }
    if (!tourismCategories.contains(trimmedCategory)) {
      throw ApiException(
        'Choose a valid tourism category.',
        code: 'invalid_request',
      );
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw ApiException(
        'Enter valid latitude and longitude values.',
        code: 'invalid_request',
      );
    }
    if (entranceFee != null && entranceFee < 0) {
      throw ApiException(
        'The entrance fee cannot be negative.',
        code: 'invalid_request',
      );
    }

    try {
      await _client.from(_sitesTable).insert({
        'name': trimmedName,
        'description': _nullIfBlank(description),
        'category': trimmedCategory,
        'location': 'SRID=4326;POINT($longitude $latitude)',
        'address': _nullIfBlank(address),
        'opening_hours': _nullIfBlank(openingHours),
        'phone': _nullIfBlank(phone),
        'entrance_fee': entranceFee,
      }).timeout(_timeout);
    } on PostgrestException catch (error) {
      throw _writeFailure(error, 'add the tourist site');
    } on TimeoutException {
      throw ApiException(
        'Adding the tourist site timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<void> deleteTouristSite(String siteId) async {
    _requireUid('delete a tourist site');
    final trimmedId = siteId.trim();
    if (trimmedId.isEmpty) {
      throw ApiException(
        'Choose a tourist site to delete.',
        code: 'invalid_request',
      );
    }
    try {
      await _client
          .from(_sitesTable)
          .delete()
          .eq('id', trimmedId)
          .timeout(_timeout);
    } on PostgrestException catch (error) {
      throw _writeFailure(error, 'delete the tourist site');
    } on TimeoutException {
      throw ApiException(
        'Deleting the tourist site timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<List<HotelModel>> getHotels() async {
    _requireUid('browse hotels');
    try {
      final rows = await _client
          .from(_hotelsTable)
          .select('$_hotelColumns, hotel_rooms($_roomColumns)')
          .order('name', ascending: true)
          .timeout(_timeout);
      return _mapHotels(rows);
    } on PostgrestException catch (error) {
      throw _readFailure(error, 'hotels');
    } on TimeoutException {
      throw ApiException(
        'Loading hotels timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<HotelModel> createHotel({
    required String name,
    required String city,
    int? starRating,
    String? description,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    _requireUid('add a hotel');
    final trimmedName = name.trim();
    final trimmedCity = city.trim();
    if (trimmedName.length < 2 || trimmedName.length > 160) {
      throw ApiException(
        'Enter a hotel name between 2 and 160 characters.',
        code: 'invalid_request',
      );
    }
    if (trimmedCity.isEmpty) {
      throw ApiException(
        'Enter the city for this hotel.',
        code: 'invalid_request',
      );
    }
    if (starRating != null && (starRating < 1 || starRating > 5)) {
      throw ApiException(
        'The star rating must be between 1 and 5.',
        code: 'invalid_request',
      );
    }
    if ((latitude == null) != (longitude == null)) {
      throw ApiException(
        'Enter both latitude and longitude, or neither.',
        code: 'invalid_request',
      );
    }
    if (latitude != null &&
        (latitude < -90 || latitude > 90 || longitude! < -180 || longitude > 180)) {
      throw ApiException(
        'Enter valid latitude and longitude values.',
        code: 'invalid_request',
      );
    }

    try {
      final row = await _client
          .from(_hotelsTable)
          .insert({
            'name': trimmedName,
            'description': _nullIfBlank(description),
            'address': _nullIfBlank(address),
            'city': trimmedCity,
            'phone': _nullIfBlank(phone),
            'latitude': latitude,
            'longitude': longitude,
            'star_rating': starRating,
            'status': 'published',
          })
          .select(_hotelColumns)
          .single()
          .timeout(_timeout);
      try {
        return HotelModel.fromRow(row);
      } on FormatException {
        throw ApiException(
          'The hotel was saved but could not be read. Refresh before retrying.',
          code: 'invalid_response',
        );
      }
    } on PostgrestException catch (error) {
      throw _writeFailure(error, 'add the hotel');
    } on TimeoutException {
      throw ApiException(
        'Adding the hotel timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<HotelRoomModel> createRoom({
    required String hotelId,
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double nightlyRate,
    String currency = 'ETB',
  }) async {
    _requireUid('add a room');
    final trimmedHotelId = hotelId.trim();
    final trimmedNumber = roomNumber.trim();
    final trimmedType = roomType.trim();
    final trimmedCurrency = currency.trim().toUpperCase();
    if (trimmedHotelId.isEmpty) {
      throw ApiException(
        'Choose the hotel for this room.',
        code: 'invalid_request',
      );
    }
    if (trimmedNumber.isEmpty || trimmedNumber.length > 20) {
      throw ApiException(
        'Enter a room number up to 20 characters.',
        code: 'invalid_request',
      );
    }
    if (trimmedType.length < 2 || trimmedType.length > 80) {
      throw ApiException(
        'Enter a room type between 2 and 80 characters.',
        code: 'invalid_request',
      );
    }
    if (capacity <= 0) {
      throw ApiException(
        'Room capacity must be at least 1.',
        code: 'invalid_request',
      );
    }
    if (nightlyRate < 0) {
      throw ApiException(
        'The nightly rate cannot be negative.',
        code: 'invalid_request',
      );
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(trimmedCurrency)) {
      throw ApiException(
        'Use a three-letter currency code, such as ETB.',
        code: 'invalid_request',
      );
    }

    try {
      final row = await _client
          .from(_roomsTable)
          .insert({
            'hotel_id': trimmedHotelId,
            'room_number': trimmedNumber,
            'room_type': trimmedType,
            'capacity': capacity,
            'nightly_rate': nightlyRate,
            'currency': trimmedCurrency,
            'status': 'available',
          })
          .select(_roomColumns)
          .single()
          .timeout(_timeout);
      try {
        return HotelRoomModel.fromRow(row);
      } on FormatException {
        throw ApiException(
          'The room was saved but could not be read. Refresh before retrying.',
          code: 'invalid_response',
        );
      }
    } on PostgrestException catch (error) {
      throw _writeFailure(error, 'add the room');
    } on TimeoutException {
      throw ApiException(
        'Adding the room timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<List<HotelReservationModel>> getReservations() async {
    _requireUid('load reservations');
    try {
      final rows = await _client
          .from(_reservationsTable)
          .select(_reservationColumns)
          .order('created_at', ascending: false)
          .limit(_listLimit)
          .timeout(_timeout);
      return _mapReservations(rows);
    } on PostgrestException catch (error) {
      throw _readFailure(error, 'reservations');
    } on TimeoutException {
      throw ApiException(
        'Loading reservations timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<HotelReservationModel> createReservation({
    required String hotelId,
    required String roomId,
    required String guestName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String? guestPhone,
  }) async {
    _requireUid('book a room');
    final trimmedHotelId = hotelId.trim();
    final trimmedRoomId = roomId.trim();
    final trimmedName = guestName.trim();
    final trimmedPhone = guestPhone?.trim();
    if (trimmedHotelId.isEmpty || trimmedRoomId.isEmpty) {
      throw ApiException(
        'Choose a hotel and a room before booking.',
        code: 'invalid_request',
      );
    }
    if (trimmedName.length < 2 || trimmedName.length > 120) {
      throw ApiException(
        'Enter the guest name (2-120 characters).',
        code: 'invalid_request',
      );
    }
    if (trimmedPhone != null &&
        trimmedPhone.isNotEmpty &&
        (trimmedPhone.length < 5 || trimmedPhone.length > 40)) {
      throw ApiException(
        'Enter a valid phone number.',
        code: 'invalid_request',
      );
    }
    final start = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final end = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!end.isAfter(start)) {
      throw ApiException(
        'Check-out must be after check-in.',
        code: 'invalid_request',
      );
    }
    if (guests <= 0) {
      throw ApiException(
        'The number of guests must be at least 1.',
        code: 'invalid_request',
      );
    }

    try {
      final row = await _client
          .from(_reservationsTable)
          .insert({
            'hotel_id': trimmedHotelId,
            'room_id': trimmedRoomId,
            'guest_name': trimmedName,
            'guest_phone':
                trimmedPhone == null || trimmedPhone.isEmpty ? null : trimmedPhone,
            'check_in': _dateOnly(start),
            'check_out': _dateOnly(end),
            'guests': guests,
          })
          .select(_reservationColumns)
          .single()
          .timeout(_timeout);
      try {
        return HotelReservationModel.fromRow(row);
      } on FormatException {
        throw ApiException(
          'The reservation was sent but could not be read. Check your reservations before retrying.',
          code: 'invalid_response',
        );
      }
    } on PostgrestException catch (error) {
      throw _reservationFailure(error);
    } on TimeoutException {
      throw ApiException(
        'Booking the room timed out. Check your reservations before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<HotelReservationModel> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async {
    _requireUid('review reservations');
    final trimmedId = reservationId.trim();
    final trimmedStatus = status.trim().toLowerCase();
    if (trimmedId.isEmpty) {
      throw ApiException(
        'Choose a reservation to review.',
        code: 'invalid_request',
      );
    }
    if (trimmedStatus != 'confirmed' && trimmedStatus != 'rejected') {
      throw ApiException(
        'Choose confirm or reject for this reservation.',
        code: 'invalid_request',
      );
    }

    try {
      final row = await _client
          .from(_reservationsTable)
          .update({'status': trimmedStatus})
          .eq('id', trimmedId)
          .eq('status', 'pending')
          .select(_reservationColumns)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) {
        throw ApiException(
          'This reservation was already decided. Refresh to see the latest status.',
          statusCode: 409,
          code: 'not_pending',
        );
      }
      try {
        return HotelReservationModel.fromRow(row);
      } on FormatException {
        throw ApiException(
          'The reservation was updated but could not be read. Refresh the list.',
          code: 'invalid_response',
        );
      }
    } on PostgrestException catch (error) {
      throw _reviewFailure(error);
    } on TimeoutException {
      throw ApiException(
        'Updating the reservation timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  List<TourismSiteModel> _mapSites(List<Map<String, dynamic>> rows) {
    try {
      return rows.map(TourismSiteModel.fromRow).toList(growable: false);
    } on FormatException {
      throw ApiException(
        'The tourist site list could not be read. Please refresh.',
        code: 'invalid_response',
      );
    }
  }

  List<HotelModel> _mapHotels(List<Map<String, dynamic>> rows) {
    try {
      return rows.map(HotelModel.fromRow).toList(growable: false);
    } on FormatException {
      throw ApiException(
        'The hotel list could not be read. Please refresh.',
        code: 'invalid_response',
      );
    }
  }

  List<HotelReservationModel> _mapReservations(
    List<Map<String, dynamic>> rows,
  ) {
    try {
      return rows
          .map(HotelReservationModel.fromRow)
          .toList(growable: false);
    } on FormatException {
      throw ApiException(
        'The reservation list could not be read. Please refresh.',
        code: 'invalid_response',
      );
    }
  }

  ApiException _readFailure(PostgrestException error, String resource) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'You do not have permission to view $resource.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST205':
        return ApiException(
          'This module is not available yet. Try again later.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again.',
          statusCode: 401,
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not load $resource. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  ApiException _writeFailure(PostgrestException error, String action) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'You do not have permission to $action.',
          code: error.code,
          originalError: error,
        );
      case '23503':
        return ApiException(
          'That hotel or room is no longer available. Refresh and try again.',
          code: error.code,
          originalError: error,
        );
      case '23505':
        return ApiException(
          'That room number already exists for this hotel.',
          code: error.code,
          originalError: error,
        );
      case '23514':
        return ApiException(
          'Some details are not allowed. Check the values and try again.',
          code: error.code,
          originalError: error,
        );
      case '22001':
        return ApiException(
          'One of the fields is too long. Shorten it and try again.',
          code: error.code,
          originalError: error,
        );
      case '22P02':
        return ApiException(
          'The selected record is not valid. Refresh and try again.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST116':
        return ApiException(
          'The record was saved but could not be read. Refresh before retrying.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again.',
          statusCode: 401,
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not $action. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  ApiException _reservationFailure(PostgrestException error) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'You do not have permission to book this room.',
          code: error.code,
          originalError: error,
        );
      case '23503':
        return ApiException(
          'That room is no longer available. Refresh and choose another room.',
          code: error.code,
          originalError: error,
        );
      case '23514':
        return ApiException(
          'The room is not available, or the dates are invalid. Choose another room or dates.',
          code: error.code,
          originalError: error,
        );
      case '22P02':
        return ApiException(
          'The hotel or room selection is not valid. Refresh and try again.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST116':
        return ApiException(
          'The reservation was sent but could not be read. Check your reservations before retrying.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again.',
          statusCode: 401,
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not book the room. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  ApiException _reviewFailure(PostgrestException error) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'Only hotel staff can review reservations.',
          code: error.code,
          originalError: error,
        );
      case '23514':
        return ApiException(
          'That reservation status change is not allowed. Refresh the list.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again.',
          statusCode: 401,
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not update the reservation. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
