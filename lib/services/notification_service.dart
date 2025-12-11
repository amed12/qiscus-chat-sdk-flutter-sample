import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qiscus_chat_flutter_sample/firebase_options.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _defaultAndroidChannel =
    AndroidNotificationChannel(
  'qiscus_chat_notifications',
  'Chat Notifications',
  description: 'Push notifications for chat messages',
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
);

/// Top-level handler required for background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance._initLocalNotifications();
  await NotificationService.instance._showRemoteNotification(message);
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  bool _localNotificationsReady = false;

  Future<void> init() async {
    if (_initialized) return;

    await _initLocalNotifications();
    await _requestPermissions();
    await _configureFirebaseListeners();
    await syncDeviceTokenWithQiscus();

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // TODO: Route to a specific screen if needed using details.payload.
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultAndroidChannel);

    _localNotificationsReady = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission denied');
    }

    // Ensure foreground notifications appear on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification when the app is launched by tapping the banner.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Register token changes to Qiscus.
    _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerTokenToQiscus(token));
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showRemoteNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened with data: ${message.data}');
    // TODO: Navigate to the correct screen using message.data if required.
  }

  Future<void> syncDeviceTokenWithQiscus() async {
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('No FCM token available to sync');
      return;
    }
    await _registerTokenToQiscus(token);
  }

  Future<void> removeDeviceToken() async {
    final token = await _messaging.getToken();
    if (token == null || !_canUseQiscus()) return;

    try {
      await QiscusService.instance.sdk.removeDeviceToken(
        token: token,
        isDevelopment: !_isProduction,
      );
      debugPrint('Device token removed from Qiscus');
    } catch (e) {
      debugPrint('Failed to remove device token: $e');
    }
  }

  bool _canUseQiscus() {
    try {
      return QiscusService.instance.sdk.isLogin;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registerTokenToQiscus(String token) async {
    if (!_canUseQiscus()) {
      debugPrint('Skip registering token, user not logged in');
      return;
    }

    try {
      await QiscusService.instance.sdk.registerDeviceToken(
        token: token,
        isDevelopment: !_isProduction,
      );
      debugPrint('Device token synced to Qiscus');
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  Future<void> _showRemoteNotification(RemoteMessage message) async {
    await _initLocalNotifications();

    final notification = message.notification;
    final android = notification?.android;

    final title =
        notification?.title ?? message.data['title'] ?? 'New message arrived';
    final body =
        notification?.body ?? message.data['body'] ?? message.data['message'];

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultAndroidChannel.id,
        _defaultAndroidChannel.name,
        channelDescription: _defaultAndroidChannel.description,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        importance: _defaultAndroidChannel.importance,
        priority: Priority.high,
        playSound: _defaultAndroidChannel.playSound,
        enableVibration: _defaultAndroidChannel.enableVibration,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      title,
      body,
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  bool get _isProduction =>
      kReleaseMode || const bool.fromEnvironment('dart.vm.product');
}
