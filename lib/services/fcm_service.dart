import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'backend_client.dart';
import 'supabase_service.dart';

/// Default Android notification channel ID. Must match AndroidManifest meta-data
/// so FCM uses this channel when displaying notifications.
const String _kAndroidChannelId = 'fcm_default_channel';
const String _kAndroidChannelName = 'Notifications';

/// FCM (Firebase Cloud Messaging) service for push notifications.
/// - On app start / when needed: get token and send to backend (Users.fcm_token).
/// - On token refresh: send new token to backend.
/// - On user login: send token to backend (auth listener calls onUserSignedIn).
/// - Foreground: show local notification so the user sees the message.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FcmService get instance => _instance;

  /// Initialize FCM: permission, Android channel, token registration, listeners.
  static Future<void> initialize() async {
    try {
      // Request permission (Android 13+ POST_NOTIFICATIONS and iOS)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS: show notification banner/sound when app is in foreground (otherwise iOS hides it)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _initLocalNotifications();

      // Send token to backend when user is logged in (may be null if auth not ready yet)
      await _registerTokenWithBackend();

      // Retry token registration after a short delay (auth session restore; on iOS, APNs token may be delayed)
      Future.delayed(const Duration(seconds: 2), () async {
        await _registerTokenWithBackend();
      });

      // When token is refreshed, send the new token to backend
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      // Foreground: show a local notification so the user sees the message
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
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
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get the current FCM token. Returns null if not available.
  /// On iOS, APNs token can be delayed; we retry once after 3s if null.
  static Future<String?> getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      // iOS: APNs token may not be ready at first call; retry once after a short delay
      if ((token == null || token.isEmpty) &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS) {
        await Future<void>.delayed(const Duration(seconds: 3));
        token = await FirebaseMessaging.instance.getToken();
      }
      return token;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    // Prefer notification payload; fall back to data for data-only messages
    String title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    String body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
    debugPrint('FCM foreground: $title - $body');
    _showLocalNotification(title: title, body: body);
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
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
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened from background: ${message.notification?.title}');
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

  /// Call when user signs in (e.g. from auth state listener) to send token to backend.
  static Future<void> onUserSignedIn() async {
    await _registerTokenWithBackend();
  }

  /// Call when app resumes so the latest token is sent (e.g. if it was refreshed while app was in background).
  static Future<void> onAppResumed() async {
    await _registerTokenWithBackend();
  }

  /// Call when user signs out (optional: clear token on backend).
  static Future<void> onUserSignedOut() async {}
}
