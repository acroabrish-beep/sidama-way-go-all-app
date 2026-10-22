import 'dart:convert';
import 'base_api_service.dart';
import '../../core/utils/logger.dart';

class DataApiService extends BaseApiService {
  // Generic GET request for any table
  Future<Map<String, dynamic>> getData(
    String table, {
    String? id,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (filters != null) {
        queryParams.addAll(filters);
      }
      
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (order != null) queryParams['order'] = order;

      final endpoint = id != null ? '/api/data/$table/$id' : '/api/data/$table';
      
      final response = await get(
        endpoint,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        AppLogger.error('Data API Error: ${response.statusCode}');
        throw Exception('Failed to fetch data from $table');
      }
    } catch (e) {
      AppLogger.error('Get data failed for $table', error: e);
      rethrow;
    }
  }

  // Generic POST request for any table
  Future<Map<String, dynamic>> createData(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await post(
        '/api/data/$table',
        body: data,
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        AppLogger.error('Data API Error: ${response.statusCode}');
        throw Exception('Failed to create data in $table');
      }
    } catch (e) {
      AppLogger.error('Create data failed for $table', error: e);
      rethrow;
    }
  }

  // Generic PATCH request for any table
  Future<Map<String, dynamic>> updateData(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await patch(
        '/api/data/$table/$id',
        body: data,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        AppLogger.error('Data API Error: ${response.statusCode}');
        throw Exception('Failed to update data in $table');
      }
    } catch (e) {
      AppLogger.error('Update data failed for $table', error: e);
      rethrow;
    }
  }

  // Generic DELETE request for any table
  Future<bool> deleteData(String table, String id) async {
    try {
      final response = await delete('/api/data/$table/$id');

      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.error('Data API Error: ${response.statusCode}');
        throw Exception('Failed to delete data from $table');
      }
    } catch (e) {
      AppLogger.error('Delete data failed for $table', error: e);
      rethrow;
    }
  }

  // Specific methods for common tables

  // Users
  Future<Map<String, dynamic>> getUser(String firebaseUid) async {
    return getData('users', filters: {'firebase_uid': firebaseUid});
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) {
    return createData('users', userData);
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> userData) {
    return updateData('users', id, userData);
  }

  // Vehicles
  Future<Map<String, dynamic>> getVehicles({Map<String, dynamic>? filters}) {
    return getData('vehicles', filters: filters);
  }

  Future<Map<String, dynamic>> getVehicle(String id) {
    return getData('vehicles', id: id);
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> vehicleData) {
    return createData('vehicles', vehicleData);
  }

  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> vehicleData) {
    return updateData('vehicles', id, vehicleData);
  }

  // Taxi Stations
  Future<Map<String, dynamic>> getTaxiStations({Map<String, dynamic>? filters}) {
    return getData('taxi_stations', filters: filters, limit: 50);
  }

  Future<Map<String, dynamic>> getTaxiStation(String id) {
    return getData('taxi_stations', id: id);
  }

  // Trips
  Future<Map<String, dynamic>> getTrips({Map<String, dynamic>? filters, int? limit}) {
    return getData('trips', filters: filters, limit: limit);
  }

  Future<Map<String, dynamic>> getTrip(String id) {
    return getData('trips', id: id);
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) {
    return createData('trips', tripData);
  }

  Future<Map<String, dynamic>> updateTrip(String id, Map<String, dynamic> tripData) {
    return updateData('trips', id, tripData);
  }

  // Hotels
  Future<Map<String, dynamic>> getHotels({Map<String, dynamic>? filters}) {
    return getData('hotels', filters: filters, limit: 50);
  }

  Future<Map<String, dynamic>> getHotel(String id) {
    return getData('hotels', id: id);
  }

  // Hospitals
  Future<Map<String, dynamic>> getHospitals({Map<String, dynamic>? filters}) {
    return getData('hospitals', filters: filters, limit: 50);
  }

  Future<Map<String, dynamic>> getHospital(String id) {
    return getData('hospitals', id: id);
  }

  // Tourism Sites
  Future<Map<String, dynamic>> getTourismSites({Map<String, dynamic>? filters}) {
    return getData('tourism_sites', filters: filters, limit: 50);
  }

  Future<Map<String, dynamic>> getTourismSite(String id) {
    return getData('tourism_sites', id: id);
  }

  // Emergency Requests
  Future<Map<String, dynamic>> getEmergencyRequests({Map<String, dynamic>? filters}) {
    return getData('emergency_requests', filters: filters, limit: 50);
  }

  Future<Map<String, dynamic>> createEmergencyRequest(Map<String, dynamic> requestData) {
    return createData('emergency_requests', requestData);
  }

  Future<Map<String, dynamic>> updateEmergencyRequest(String id, Map<String, dynamic> requestData) {
    return updateData('emergency_requests', id, requestData);
  }

  // Announcements
  Future<Map<String, dynamic>> getAnnouncements({Map<String, dynamic>? filters}) {
    return getData('announcements', filters: filters, limit: 20);
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications(String userId, {bool? isRead}) {
    return getData('notifications', filters: {
      'user_id': userId,
      if (isRead != null) 'is_read': isRead.toString(),
    });
  }

  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notificationData) {
    return createData('notifications', notificationData);
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String id) {
    return updateData('notifications', id, {'is_read': true});
  }

  // Payments
  Future<Map<String, dynamic>> getPayments(String userId) {
    return getData('payments', filters: {'user_id': userId});
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData) {
    return createData('payments', paymentData);
  }

  Future<Map<String, dynamic>> updatePayment(String id, Map<String, dynamic> paymentData) {
    return updateData('payments', id, paymentData);
  }

  // Wallet Transactions
  Future<Map<String, dynamic>> getWalletTransactions(String userId) {
    return getData('wallet_transactions', filters: {'user_id': userId});
  }

  Future<Map<String, dynamic>> createWalletTransaction(Map<String, dynamic> transactionData) {
    return createData('wallet_transactions', transactionData);
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics({String? metricName}) {
    if (metricName != null) {
      return getData('analytics', filters: {'metric_name': metricName});
    }
    return getData('analytics', limit: 100);
  }
}