import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists Apple-provided profile fields (only sent on first authorization).
class AppleSignInCache {
  AppleSignInCache._();

  static const _storageKeyPrefix = 'apple_sign_in_profile_';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save({
    required String userIdentifier,
    String? fullName,
    String? givenName,
    String? familyName,
    String? email,
  }) async {
    final id = userIdentifier.trim();
    if (id.isEmpty) return;

    final existing = await load(id);
    final payload = <String, String>{
      if (existing?.fullName != null) 'fullName': existing!.fullName!,
      if (existing?.givenName != null) 'givenName': existing!.givenName!,
      if (existing?.familyName != null) 'familyName': existing!.familyName!,
      if (existing?.email != null) 'email': existing!.email!,
    };

    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) payload['fullName'] = full;

    final given = givenName?.trim();
    if (given != null && given.isNotEmpty) payload['givenName'] = given;

    final family = familyName?.trim();
    if (family != null && family.isNotEmpty) payload['familyName'] = family;

    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) payload['email'] = mail;

    if (payload.isEmpty) return;

    await _storage.write(
      key: '$_storageKeyPrefix$id',
      value: jsonEncode(payload),
    );
  }

  static Future<AppleCachedProfile?> load(String userIdentifier) async {
    final id = userIdentifier.trim();
    if (id.isEmpty) return null;

    final raw = await _storage.read(key: '$_storageKeyPrefix$id');
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return AppleCachedProfile(
        fullName: map['fullName']?.toString(),
        givenName: map['givenName']?.toString(),
        familyName: map['familyName']?.toString(),
        email: map['email']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

class AppleCachedProfile {
  const AppleCachedProfile({
    this.fullName,
    this.givenName,
    this.familyName,
    this.email,
  });

  final String? fullName;
  final String? givenName;
  final String? familyName;
  final String? email;
}
