import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/utils/logger.dart';

class OfflineRequest {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final int timestamp;
  final int retryCount;
  final String? error;

  OfflineRequest({
    required this.id,
    required this.endpoint,
    required this.method,
    this.body,
    this.headers,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
  }) {
    // Note: retryCount is final, so default value set via parameter
  }

  OfflineRequest copyWith({
    String? id,
    String? endpoint,
    String? method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int? timestamp,
    int? retryCount,
    String? error,
  }) {
    return OfflineRequest(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'body': jsonEncode(body),
      'headers': jsonEncode(headers),
      'timestamp': timestamp,
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory OfflineRequest.fromMap(Map<String, dynamic> map) {
    return OfflineRequest(
      id: map['id'],
      endpoint: map['endpoint'],
      method: map['method'],
      body: map['body'] != null ? jsonDecode(map['body']) : null,
      headers: map['headers'] != null ? jsonDecode(map['headers']) : null,
      timestamp: map['timestamp'],
      retryCount: map['retryCount'] ?? 0,
      error: map['error'],
    );
  }
}

class OfflineCacheItem {
  final String key;
  final String data;
  final int timestamp;
  final int? expiryTime;

  OfflineCacheItem({
    required this.key,
    required this.data,
    required this.timestamp,
    this.expiryTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp,
      'expiryTime': expiryTime,
    };
  }

  factory OfflineCacheItem.fromMap(Map<String, dynamic> map) {
    return OfflineCacheItem(
      key: map['key'],
      data: map['data'],
      timestamp: map['timestamp'],
      expiryTime: map['expiryTime'],
    );
  }

  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiryTime!;
  }
}

class OfflineService {
  static OfflineService? _instance;
  Database? _database;
  final Map<String, OfflineCacheItem> _memoryCache = {};
  final List<OfflineRequest> _pendingRequests = [];
  final List<OfflineRequest> _retryQueue = [];
  Timer? _syncTimer;
  bool _isOnline = true;
  final List<void Function()> _onlineListeners = [];

  static const int _maxRetryCount = 3;
  static const int _syncIntervalSeconds = 30;

  static OfflineService get instance {
    _instance ??= OfflineService._();
    return _instance!;
  }

  OfflineService._() {
    _initializeDatabase();
    _startSyncTimer();
  }

  Future<void> _initializeDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'sidama_way_go_offline.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE offline_cache (
              key TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              expiryTime INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE pending_requests (
              id TEXT PRIMARY KEY,
              endpoint TEXT NOT NULL,
              method TEXT NOT NULL,
              body TEXT,
              headers TEXT,
              timestamp INTEGER NOT NULL,
              retryCount INTEGER DEFAULT 0,
              error TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE offline_sessions (
              firebase_uid TEXT PRIMARY KEY,
              session_data TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE offline_tickets (
              ticket_id TEXT PRIMARY KEY,
              ticket_data TEXT NOT NULL,
              validated BOOLEAN DEFAULT false,
              timestamp INTEGER NOT NULL
            )
          ''');
        },
      );

      AppLogger.info('Offline database initialized');
      await _loadPendingRequests();
    } catch (e) {
      AppLogger.error('Failed to initialize offline database', error: e);
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query('pending_requests');
      _pendingRequests.clear();
      _retryQueue.clear();

      for (final map in maps) {
        final request = OfflineRequest.fromMap(map);
        if (request.retryCount < _maxRetryCount) {
          _retryQueue.add(request);
        } else {
          _pendingRequests.add(request);
        }
      }

      AppLogger.info('Loaded ${_pendingRequests.length} pending requests');
      AppLogger.info('Loaded ${_retryQueue.length} retryable requests');
    } catch (e) {
      AppLogger.error('Failed to load pending requests', error: e);
    }
  }

  // Cache management
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    final item = OfflineCacheItem(
      key: key,
      data: jsonEncode(data),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      expiryTime: expiry != null 
          ? DateTime.now().add(expiry).millisecondsSinceEpoch 
          : null,
    );

    // Memory cache
    _memoryCache[key] = item;

    // Persistent cache
    if (_database != null) {
      try {
        await _database!.insert(
          'offline_cache',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        AppLogger.error('Failed to cache data', error: e);
      }
    }

    AppLogger.info('Cached data: $key');
  }

  Future<T?> getCachedData<T>(String key) async {
    // Check memory cache first
    final memoryItem = _memoryCache[key];
    if (memoryItem != null && !memoryItem.isExpired) {
      try {
        return jsonDecode(memoryItem.data) as T;
      } catch (e) {
        AppLogger.error('Failed to decode cached data from memory', error: e);
      }
    }

    // Check persistent cache
    if (_database != null) {
      try {
        final List<Map<String, dynamic>> maps = await _database!.query(
          'offline_cache',
          where: 'key = ?',
          whereArgs: [key],
        );

        if (maps.isNotEmpty) {
          final item = OfflineCacheItem.fromMap(maps.first);
          
          if (item.isExpired) {
            await _database!.delete('offline_cache', where: 'key = ?', whereArgs: [key]);
            return null;
          }

          // Update memory cache
          _memoryCache[key] = item;
          
          try {
            return jsonDecode(item.data) as T;
          } catch (e) {
            AppLogger.error('Failed to decode cached data', error: e);
          }
        }
      } catch (e) {
        AppLogger.error('Failed to get cached data', error: e);
      }
    }

    return null;
  }

  Future<void> clearCache({String? key}) async {
    if (key != null) {
      _memoryCache.remove(key);
      if (_database != null) {
        await _database!.delete('offline_cache', where: 'key = ?', whereArgs: [key]);
      }
    } else {
      _memoryCache.clear();
      if (_database != null) {
        await _database!.delete('offline_cache');
      }
    }
    AppLogger.info('Cleared cache: ${key ?? "all"}');
  }

  // Request queue management
  Future<void> queueRequest(OfflineRequest request) async {
    _pendingRequests.add(request);
    
    if (_database != null) {
      try {
        await _database!.insert(
          'pending_requests',
          request.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        AppLogger.error('Failed to queue request', error: e);
      }
    }

    AppLogger.info('Queued request: ${request.endpoint}');
    
    if (_isOnline) {
      _processRetryQueue();
    }
  }

  Future<void> _processRetryQueue() async {
    if (!_isOnline || _retryQueue.isEmpty) return;

    AppLogger.info('Processing retry queue: ${_retryQueue.length} requests');

    final requestsToProcess = List<OfflineRequest>.from(_retryQueue);
    _retryQueue.clear();

    for (final request in requestsToProcess) {
      try {
        // This would integrate with the actual API service
        // For now, we simulate successful processing
        await _simulateRequestProcessing(request);
        
        // Remove from database
        if (_database != null) {
          await _database!.delete(
            'pending_requests',
            where: 'id = ?',
            whereArgs: [request.id],
          );
        }
      } catch (e) {
        final updatedRequest = request.copyWith(
          retryCount: request.retryCount + 1,
          error: e.toString(),
        );
        
        if (updatedRequest.retryCount < _maxRetryCount) {
          _retryQueue.add(updatedRequest);
        } else {
          _pendingRequests.add(updatedRequest);
        }

        if (_database != null) {
          await _database!.update(
            'pending_requests',
            updatedRequest.toMap(),
            where: 'id = ?',
            whereArgs: [updatedRequest.id],
          );
        }
      }
    }
  }

  Future<void> _simulateRequestProcessing(OfflineRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In production, this would call the actual API
    AppLogger.info('Processed request: ${request.endpoint}');
  }

  // Offline session management
  Future<void> saveOfflineSession(String firebaseUid, Map<String, dynamic> sessionData) async {
    if (_database == null) return;

    try {
      await _database!.insert(
        'offline_sessions',
        {
          'firebase_uid': firebaseUid,
          'session_data': jsonEncode(sessionData),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info('Saved offline session for user: $firebaseUid');
    } catch (e) {
      AppLogger.error('Failed to save offline session', error: e);
    }
  }

  Future<Map<String, dynamic>?> getOfflineSession(String firebaseUid) async {
    if (_database == null) return null;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'offline_sessions',
        where: 'firebase_uid = ?',
        whereArgs: [firebaseUid],
      );

      if (maps.isNotEmpty) {
        return jsonDecode(maps.first['session_data']);
      }
    } catch (e) {
      AppLogger.error('Failed to get offline session', error: e);
    }

    return null;
  }

  // Offline ticket validation
  Future<void> saveOfflineTicket(String ticketId, Map<String, dynamic> ticketData) async {
    if (_database == null) return;

    try {
      await _database!.insert(
        'offline_tickets',
        {
          'ticket_id': ticketId,
          'ticket_data': jsonEncode(ticketData),
          'validated': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info('Saved offline ticket: $ticketId');
    } catch (e) {
      AppLogger.error('Failed to save offline ticket', error: e);
    }
  }

  Future<Map<String, dynamic>?> getOfflineTicket(String ticketId) async {
    if (_database == null) return null;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'offline_tickets',
        where: 'ticket_id = ?',
        whereArgs: [ticketId],
      );

      if (maps.isNotEmpty) {
        return jsonDecode(maps.first['ticket_data']);
      }
    } catch (e) {
      AppLogger.error('Failed to get offline ticket', error: e);
    }

    return null;
  }

  Future<bool> validateOfflineTicket(String ticketId) async {
    if (_database == null) return false;

    try {
      await _database!.update(
        'offline_tickets',
        {'validated': true},
        where: 'ticket_id = ?',
        whereArgs: [ticketId],
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to validate offline ticket', error: e);
      return false;
    }
  }

  // Network status management
  void setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      AppLogger.info('Network status changed: ${isOnline ? "online" : "offline"}');

      if (isOnline) {
        _processRetryQueue();
        _notifyOnlineListeners();
      }
    }
  }

  void addOnlineListener(void Function() listener) {
    _onlineListeners.add(listener);
  }

  void removeOnlineListener(void Function() listener) {
    _onlineListeners.remove(listener);
  }

  void _notifyOnlineListeners() {
    for (final listener in _onlineListeners) {
      try {
        listener();
      } catch (e) {
        AppLogger.error('Error in online listener', error: e);
      }
    }
  }

  // Sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: _syncIntervalSeconds),
      (_) {
        if (_isOnline) {
          _processRetryQueue();
        }
      },
    );
  }

  // Cleanup
  Future<void> cleanup() async {
    _syncTimer?.cancel();
    
    // Clear expired cache
    if (_database != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database!.delete(
        'offline_cache',
        where: 'expiryTime < ?',
        whereArgs: [now],
      );
    }

    AppLogger.info('Offline service cleanup completed');
  }

  // Statistics
  Map<String, int> get statistics {
    return {
      'memoryCacheSize': _memoryCache.length,
      'pendingRequests': _pendingRequests.length,
      'retryQueue': _retryQueue.length,
      'onlineListeners': _onlineListeners.length,
    };
  }
}