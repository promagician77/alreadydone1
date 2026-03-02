import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'backend_client.dart';
import 'supabase_service.dart';

/// FCM (Firebase Cloud Messaging) service for push notifications.
/// Handles token retrieval, permission, sending token to backend, and foreground messages.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();

  static FcmService get instance => _instance;

  /// Initialize FCM: request permission, get token, register foreground handler.
  /// Call after Firebase.initializeApp() and when user is authenticated.
  static Future<void> initialize() async {
    try {
      // Request permission (Android 13+ and iOS)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get and send FCM token to backend when user is logged in
      await _registerTokenWithBackend();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Optional: handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
  }

  /// Get the current FCM token. Returns null if not available.
  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM foreground: ${message.notification?.title} - ${message.notification?.body}',
    );
    // You can show an in-app banner or snackbar here if desired.
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened from background: ${message.notification?.title}');
    // Optionally navigate to a specific screen.
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

  /// Call when user signs in to ensure token is registered.
  static Future<void> onUserSignedIn() async {
    await _registerTokenWithBackend();
  }

  /// Call when user signs out to optionally clear token on backend (optional).
  /// Backend may keep the token; clearing is app-specific.
  static Future<void> onUserSignedOut() async {
    // No-op unless you want to send empty token to backend
  }
}
