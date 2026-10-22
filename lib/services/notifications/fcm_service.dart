import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/logger.dart';
import '../api/data_api_service.dart';

enum NotificationType {
  emergency,
  tripAccepted,
  tripCancelled,
  vehicleTransferred,
  wallet,
  payment,
  announcement,
  governmentAlert,
  ai,
  admin,
}

class NotificationData {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final String? imageUrl;

  NotificationData({
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.imageUrl,
  });

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseNotificationType(map['type']),
      data: map['data'],
      imageUrl: map['imageUrl'],
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'emergency':
        return NotificationType.emergency;
      case 'trip_accepted':
        return NotificationType.tripAccepted;
      case 'trip_cancelled':
        return NotificationType.tripCancelled;
      case 'vehicle_transferred':
        return NotificationType.vehicleTransferred;
      case 'wallet':
        return NotificationType.wallet;
      case 'payment':
        return NotificationType.payment;
      case 'announcement':
        return NotificationType.announcement;
      case 'government_alert':
        return NotificationType.governmentAlert;
      case 'ai':
        return NotificationType.ai;
      case 'admin':
        return NotificationType.admin;
      default:
        return NotificationType.announcement;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'imageUrl': imageUrl,
    };
  }
}

class FCMService {
  static FCMService? _instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DataApiService _dataApiService = DataApiService();

  static const String _emergencyTopic = 'emergency';
  static const String _announcementTopic = 'announcements';
  static const String _governmentTopic = 'government';

  static FCMService get instance {
    _instance ??= FCMService._();
    return _instance!;
  }

  FCMService._();

  Future<void> initialize() async {
    try {
      // Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        AppLogger.info('FCM Token: $token');

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Configure handlers
        _configureForegroundHandler();
        _configureBackgroundHandler();
        _configureTerminatedStateHandler();

        // Subscribe to default topics
        await _subscribeToDefaultTopics();

        AppLogger.info('FCM Service initialized successfully');
      } else {
        AppLogger.warning('FCM Permission not granted');
      }
    } catch (e) {
      AppLogger.error('FCM initialization failed', error: e);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    AppLogger.info('Local notifications initialized');
  }

  void _configureForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Received foreground message: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });
  }

  void _configureBackgroundHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('Opened app from notification: ${message.notification?.title}');
      _handleNotificationTap(message.data);
    });
  }

  Future<void> _configureTerminatedStateHandler() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from terminated state via notification');
      _handleNotificationTap(initialMessage.data);
    }
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      await _messaging.subscribeToTopic(_emergencyTopic);
      await _messaging.subscribeToTopic(_announcementTopic);
      await _messaging.subscribeToTopic(_governmentTopic);
      AppLogger.info('Subscribed to default topics');
    } catch (e) {
      AppLogger.error('Failed to subscribe to default topics', error: e);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', error: e);
    }
  }

  Future<void> subscribeToUserRole(String role) async {
    final topic = 'role_$role';
    await subscribeToTopic(topic);
  }

  Future<void> subscribeToUserSpecific(String userId) async {
    final topic = 'user_$userId';
    await subscribeToTopic(topic);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      await _showLocalNotification(
        notification.title ?? 'Sidama Way Go',
        notification.body ?? '',
        data,
        notification.android?.imageUrl,
      );
    }

    // Save notification to database
    await _saveNotificationToDatabase(message);
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  ) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sidama_way_go_channel',
      'Sidama Way Go Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        htmlFormatTitle: true,
      ),
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationTap(data);
      } catch (e) {
        AppLogger.error('Failed to parse notification payload', error: e);
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Navigate based on notification type
    final type = data['type'];
    AppLogger.info('Notification tapped with type: $type');

    // This would integrate with navigation service
    // For now, we just log the tap
  }

  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // This would save to Supabase via API
      // For now, we just log
      AppLogger.info('Notification saved to database: ${notification.title}');
    } catch (e) {
      AppLogger.error('Failed to save notification to database', error: e);
    }
  }

  // Notification sending methods (would be called from backend)

  Future<void> sendEmergencyNotification({
    required String title,
    required String body,
    required String location,
    String? severity,
  }) async {
    final data = {
      'type': 'emergency',
      'location': location,
      'severity': severity ?? 'medium',
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotification(
      topic: _emergencyTopic,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> sendTripNotification({
    required String userId,
    required String title,
    required String body,
    required String tripId,
    required String status,
  }) async {
    final data = {
      'type': 'trip_update',
      'trip_id': tripId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotification(
      topic: 'user_$userId',
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> sendWalletNotification({
    required String userId,
    required String title,
    required String body,
    required double amount,
    required String transactionType,
  }) async {
    final data = {
      'type': 'wallet',
      'amount': amount,
      'transaction_type': transactionType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotification(
      topic: 'user_$userId',
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
    List<String>? targetRoles,
    String? priority,
  }) async {
    final data = {
      'type': 'announcement',
      'priority': priority ?? 'normal',
      'target_roles': targetRoles,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (targetRoles != null && targetRoles.isNotEmpty) {
      // Send to specific role topics
      for (final role in targetRoles) {
        await _sendNotification(
          topic: 'role_$role',
          title: title,
          body: body,
          data: data,
        );
      }
    } else {
      // Send to general announcement topic
      await _sendNotification(
        topic: _announcementTopic,
        title: title,
        body: body,
        data: data,
      );
    }
  }

  Future<void> sendGovernmentAlert({
    required String title,
    required String body,
    String? jurisdiction,
  }) async {
    final data = {
      'type': 'government_alert',
      'jurisdiction': jurisdiction,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotification(
      topic: _governmentTopic,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> _sendNotification({
    required String topic,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // This would call the backend API to send the notification
    // For now, we just log
    AppLogger.info('Sending notification to topic: $topic');
    AppLogger.info('Title: $title');
    AppLogger.info('Body: $body');
    AppLogger.info('Data: $data');
  }

  // Token management
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', error: e);
      return null;
    }
  }

  Future<void> refreshToken() async {
    try {
      await _messaging.deleteToken();
      final newToken = await _messaging.getToken();
      AppLogger.info('FCM Token refreshed: $newToken');
    } catch (e) {
      AppLogger.error('Failed to refresh FCM token', error: e);
    }
  }

  // Notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    try {
      final result = await _dataApiService.getNotifications(userId);
      return result['data'] as List<Map<String, dynamic>>;
    } catch (e) {
      AppLogger.error('Failed to get notification history', error: e);
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dataApiService.markNotificationAsRead(notificationId);
      AppLogger.info('Notification marked as read: $notificationId');
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', error: e);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await getNotificationHistory(userId);
      for (final notification in notifications) {
        if (notification['is_read'] == false) {
          await markAsRead(notification['id']);
        }
      }
      AppLogger.info('All notifications marked as read for user: $userId');
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', error: e);
    }
  }
}