import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/flutter_flow/nav/nav.dart';
import 'backend_client.dart';
import 'supabase_service.dart';

const String _kAndroidChannelId = 'fcm_default_channel';
const String _kAndroidChannelName = 'Notifications';

const String _kStoryReminderRoute = '/onboarding/desire';

class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FcmService get instance => _instance;

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('FcmService: skipping init (no Firebase app)');
      return;
    }
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _initLocalNotifications();

      await _registerTokenWithBackend();

      Future.delayed(const Duration(seconds: 5), () async {
        await _registerTokenWithBackend();
      });

      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageData(initialMessage.data);
      }
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _kAndroidChannelId,
        _kAndroidChannelName,
        description: 'Push notifications from Already Done',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    Map<String, String> data = {};
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          data = decoded.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          );
        }
      } catch (e) {
        debugPrint('FCM notification payload parse error: $e');
      }
    }
    _handleNotificationTap(data: data);
  }

  /// Get the current FCM token. Returns null if not available.
  /// On iOS, explicitly waits for APNs token before requesting FCM token.
  static Future<String?> getToken() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken =
            await FirebaseMessaging.instance.getAPNSToken();
        int retries = 0;
        const maxRetries = 5;
        while (apnsToken == null && retries < maxRetries) {
          debugPrint(
              'FCM: APNS token not ready, retry ${retries + 1}/$maxRetries...');
          await Future<void>.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          debugPrint(
              'FCM: APNS token not available after $maxRetries retries');
          return null;
        }
        debugPrint(
            'FCM: APNS token obtained (length: ${apnsToken.length})');
      }

      final token = await FirebaseMessaging.instance.getToken();
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final String title = message.notification?.title ??
        message.data['title'] ??
        'Notification';
    final String body = message.notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';
    debugPrint('FCM foreground: $title - $body');
    _showLocalNotification(
      title: title,
      body: body,
      data: message.data.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      _kAndroidChannelName,
      channelDescription: 'Push notifications from Already Done',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(0x7FFFFFFF),
      title,
      body,
      details,
      payload: data != null && data.isNotEmpty ? jsonEncode(data) : null,
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint(
        'FCM opened from background: ${message.notification?.title}');
    _handleRemoteMessageData(message.data);
  }

  static void _handleRemoteMessageData(Map<String, dynamic> data) {
    _handleNotificationTap(
      data: data.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
    );
  }

  static void _handleNotificationTap({
    required Map<String, String> data,
  }) {
    final route = data['route']?.trim();
    final type = data['type']?.trim();

    if (type == 'monday' || type == 'thursday') {
      _navigateToRoute(
        (route != null && route.isNotEmpty) ? route : _kStoryReminderRoute,
      );
      return;
    }

    if (route != null && route.isNotEmpty) {
      _navigateToRoute(route);
    }
  }

  static void _navigateToRoute(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      GoRouter.of(ctx).go(route);
    });
  }

  static void _onTokenRefresh(String newToken) {
    debugPrint('FCM token refreshed');
    _sendTokenToBackend(newToken);
  }

  static Future<void> _registerTokenWithBackend() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      debugPrint('FCM token obtained (length: ${token.length})');
      await _sendTokenToBackend(token);
    } else {
      debugPrint('FCM token is null or empty');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return;
    try {
      await BackendClient.updateUserProfile(userId, fcmToken: token);
      debugPrint('FCM token sent to backend for user $userId');
    } catch (e) {
      debugPrint('FCM token send to backend failed: $e');
    }
  }

  static Future<void> onUserSignedIn() async {
    await _registerTokenWithBackend();
  }

  static Future<void> onAppResumed() async {
    await _registerTokenWithBackend();
  }

  static Future<void> onUserSignedOut() async {}
}
