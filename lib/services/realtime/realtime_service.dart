import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';

enum RealtimeEventType {
  vehicleUpdate,
  stationUpdate,
  tripUpdate,
  emergencyUpdate,
  notificationUpdate,
  walletUpdate,
  dashboardUpdate,
}

class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> data;
  final String? recordId;

  RealtimeEvent({
    required this.type,
    required this.data,
    this.recordId,
  });
}

typedef RealtimeCallback = void Function(RealtimeEvent event);

class RealtimeService {
  static RealtimeService? _instance;
  final Map<RealtimeEventType, List<RealtimeCallback>> _listeners = {};
  final Map<String, RealtimeChannel> _channels = {};

  static RealtimeService get instance {
    _instance ??= RealtimeService._();
    return _instance!;
  }

  RealtimeService._();

  // Subscribe to vehicle updates
  void subscribeToVehicles({String? vehicleId}) {
    final channelName = vehicleId != null ? 'vehicles:$vehicleId' : 'vehicles';
    
    if (_channels.containsKey(channelName)) {
      AppLogger.info('Already subscribed to $channelName');
      return;
    }

    final channel = Supabase.instance.client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicles',
          filter: vehicleId != null ? PostgresChangeFilter(column: 'id', type: PostgresChangeFilterType.eq, value: vehicleId) : null,
          callback: (payload) {
            AppLogger.info('Vehicle update received: ${payload.eventType}');
            _notifyListeners(RealtimeEventType.vehicleUpdate, {
              'eventType': payload.eventType,
              'old': payload.oldRecord,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Vehicle subscription status: $status');
          if (error != null) {
            AppLogger.error('Vehicle subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to vehicle updates: $channelName');
  }

  // Subscribe to station updates
  void subscribeToStations({String? stationId}) {
    final channelName = stationId != null ? 'stations:$stationId' : 'stations';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'taxi_stations',
          filter: stationId != null ? PostgresChangeFilter(column: 'id', type: PostgresChangeFilterType.eq, value: stationId) : null,
          callback: (payload) {
            AppLogger.info('Station update received: ${payload.eventType}');
            _notifyListeners(RealtimeEventType.stationUpdate, {
              'eventType': payload.eventType,
              'old': payload.oldRecord,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Station subscription status: $status');
          if (error != null) {
            AppLogger.error('Station subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to station updates: $channelName');
  }

  // Subscribe to trip updates
  void subscribeToTrips({String? tripId, String? userId}) {
    final channelName = tripId != null ? 'trips:$tripId' : userId != null ? 'trips:user:$userId' : 'trips';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    PostgresChangeFilter? filter;
    if (tripId != null) {
      filter = PostgresChangeFilter(column: 'id', type: PostgresChangeFilterType.eq, value: tripId);
    } else if (userId != null) {
      filter = PostgresChangeFilter(column: 'passenger_id', type: PostgresChangeFilterType.eq, value: userId);
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: filter,
          callback: (payload) {
            AppLogger.info('Trip update received: ${payload.eventType}');
            _notifyListeners(RealtimeEventType.tripUpdate, {
              'eventType': payload.eventType,
              'old': payload.oldRecord,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Trip subscription status: $status');
          if (error != null) {
            AppLogger.error('Trip subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to trip updates: $channelName');
  }

  // Subscribe to emergency requests
  void subscribeToEmergencyRequests({String? requestId, String? userId}) {
    final channelName = requestId != null ? 'emergency:$requestId' : userId != null ? 'emergency:user:$userId' : 'emergency';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    PostgresChangeFilter? filter;
    if (requestId != null) {
      filter = PostgresChangeFilter(column: 'id', type: PostgresChangeFilterType.eq, value: requestId);
    } else if (userId != null) {
      filter = PostgresChangeFilter(column: 'user_id', type: PostgresChangeFilterType.eq, value: userId);
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'emergency_requests',
          filter: filter,
          callback: (payload) {
            AppLogger.info('Emergency update received: ${payload.eventType}');
            _notifyListeners(RealtimeEventType.emergencyUpdate, {
              'eventType': payload.eventType,
              'old': payload.oldRecord,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Emergency subscription status: $status');
          if (error != null) {
            AppLogger.error('Emergency subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to emergency updates: $channelName');
  }

  // Subscribe to notifications
  void subscribeToNotifications(String userId) {
    final channelName = 'notifications:$userId';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(column: 'user_id', type: PostgresChangeFilterType.eq, value: userId),
          callback: (payload) {
            AppLogger.info('Notification received');
            _notifyListeners(RealtimeEventType.notificationUpdate, {
              'eventType': payload.eventType,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Notification subscription status: $status');
          if (error != null) {
            AppLogger.error('Notification subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to notifications: $channelName');
  }

  // Subscribe to wallet updates
  void subscribeToWallet(String userId) {
    final channelName = 'wallet:$userId';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallet_transactions',
          filter: PostgresChangeFilter(column: 'user_id', type: PostgresChangeFilterType.eq, value: userId),
          callback: (payload) {
            AppLogger.info('Wallet update received');
            _notifyListeners(RealtimeEventType.walletUpdate, {
              'eventType': payload.eventType,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Wallet subscription status: $status');
          if (error != null) {
            AppLogger.error('Wallet subscription error', error: error);
          }
        });

    // Also listen to user balance changes
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(column: 'id', type: PostgresChangeFilterType.eq, value: userId),
          callback: (payload) {
            AppLogger.info('User balance update received');
            _notifyListeners(RealtimeEventType.walletUpdate, {
              'eventType': payload.eventType,
              'new': payload.newRecord,
            }, payload.newRecord['id']?.toString());
          },
        )
        .subscribe((status, error) {
          AppLogger.info('User balance subscription status: $status');
          if (error != null) {
            AppLogger.error('User balance subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to wallet updates: $channelName');
  }

  // Subscribe to dashboard KPI updates
  void subscribeToDashboardKPIs() {
    final channelName = 'dashboard_kpis';
    
    if (_channels.containsKey(channelName)) return;

    final channel = Supabase.instance.client.channel(channelName);

    // Listen to analytics updates
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'analytics',
          callback: (payload) {
            AppLogger.info('Dashboard KPI update received');
            _notifyListeners(RealtimeEventType.dashboardUpdate, {
              'eventType': payload.eventType,
              'new': payload.newRecord,
            });
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Analytics subscription status: $status');
          if (error != null) {
            AppLogger.error('Analytics subscription error', error: error);
          }
        });

    // Listen to trip count changes
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          callback: (payload) {
            AppLogger.info('Trip count update received');
            _notifyListeners(RealtimeEventType.dashboardUpdate, {
              'eventType': payload.eventType,
              'table': 'trips',
            });
          },
        )
        .subscribe((status, error) {
          AppLogger.info('Trip count subscription status: $status');
          if (error != null) {
            AppLogger.error('Trip count subscription error', error: error);
          }
        });

    _channels[channelName] = channel;
    AppLogger.info('Subscribed to dashboard KPIs: $channelName');
  }

  // Add listener for specific event type
  void addListener(RealtimeEventType type, RealtimeCallback callback) {
    if (!_listeners.containsKey(type)) {
      _listeners[type] = [];
    }
    _listeners[type]!.add(callback);
    AppLogger.info('Added listener for $type');
  }

  // Remove listener
  void removeListener(RealtimeEventType type, RealtimeCallback callback) {
    _listeners[type]?.remove(callback);
    AppLogger.info('Removed listener for $type');
  }

  // Unsubscribe from specific channel
  void unsubscribe(String channelName) {
    final channel = _channels[channelName];
    if (channel != null) {
      channel.unsubscribe();
      _channels.remove(channelName);
      AppLogger.info('Unsubscribed from $channelName');
    }
  }

  // Unsubscribe from all channels
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
    _listeners.clear();
    AppLogger.info('Unsubscribed from all channels');
  }

  // Notify all listeners of an event
  void _notifyListeners(RealtimeEventType type, Map<String, dynamic> data, [String? recordId]) {
    final event = RealtimeEvent(type: type, data: data, recordId: recordId);
    final callbacks = _listeners[type];
    
    if (callbacks != null) {
      for (final callback in callbacks) {
        try {
          callback(event);
        } catch (e) {
          AppLogger.error('Error in realtime callback', error: e);
        }
      }
    }
  }

  // Get active subscriptions count
  int get activeSubscriptions => _channels.length;

  // Get listeners count
  int get listenersCount => _listeners.values.fold(0, (sum, list) => sum + list.length);
}