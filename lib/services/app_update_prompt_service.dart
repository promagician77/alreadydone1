import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '/flutter_flow/nav/nav.dart';
import '/services/backend_client.dart';

/// Soft, dismissible "new version available" dialog driven by backend
/// [GET /api/mobile-app/update].
class AppUpdatePromptService {
  AppUpdatePromptService._();

  static const _kSnoozeUntilMs = 'app_update_snooze_until_ms';
  static const _kDismissedLatestBuild = 'app_update_dismissed_latest_build';
  static const _androidPackageId = 'com.mycompany.alreadyapp';

  static const Duration _snooze = Duration(days: 3);

  static const _defaultBody =
      'A new version of Already Done is available. Update for the latest improvements.';

  static Future<void> checkAndMaybeShow() async {
    if (kIsWeb) return;

    late final int currentBuild;
    late final String currentVersion;
    try {
      final pkg = await PackageInfo.fromPlatform();
      currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      currentVersion = pkg.version;
    } catch (e) {
      debugPrint('AppUpdatePrompt: PackageInfo failed: $e');
      return;
    }

    final payload = await BackendClient.fetchMobileAppUpdateInfo();
    if (payload == null) return;
    if (currentBuild >= payload.latestBuild) return;

    final prefs = await SharedPreferences.getInstance();
    if (!_shouldShowAfterSnooze(prefs, payload.latestBuild)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showDialog(
        prefs: prefs,
        payload: payload,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ));
    });
  }

  static bool _shouldShowAfterSnooze(SharedPreferences prefs, int latestBuild) {
    final dismissedFor = prefs.getInt(_kDismissedLatestBuild) ?? -1;
    final snoozeUntil = prefs.getInt(_kSnoozeUntilMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (latestBuild > dismissedFor) return true;
    if (now >= snoozeUntil) return true;
    return false;
  }

  static String? _storeUrlForPlatform(MobileAppUpdatePayload p) {
    if (Platform.isIOS) {
      final u = p.iosStoreUrl?.trim();
      if (u != null && u.isNotEmpty) return u;
      return null;
    }
    if (Platform.isAndroid) {
      final u = p.androidStoreUrl?.trim();
      if (u != null && u.isNotEmpty) return u;
      return 'https://play.google.com/store/apps/details?id=$_androidPackageId';
    }
    return null;
  }

  /// Prefer App Store app via itms-apps; plain https often opens Safari and can fail on some iOS versions.
  static Uri? _iosLaunchUriForStoreUrl(String storeUrl) {
    final raw = storeUrl.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed == null || !parsed.hasScheme) return null;

    final host = parsed.host.toLowerCase();
    if (host.contains('apps.apple.com') || host.contains('itunes.apple.com')) {
      final idMatch = RegExp(r'/id(\d+)').firstMatch(parsed.path);
      if (idMatch != null) {
        final id = idMatch.group(1)!;
        return Uri.parse('itms-apps://apps.apple.com/app/id$id');
      }
    }
    if (parsed.scheme == 'itms-apps' || parsed.scheme == 'itms') {
      return parsed;
    }
    return parsed;
  }

  static Future<bool> _launchStoreUri(Uri uri) async {
    if (Platform.isIOS) {
      if (await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
      return launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _showDialog({
    required SharedPreferences prefs,
    required MobileAppUpdatePayload payload,
    required String currentVersion,
    required int currentBuild,
  }) async {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final storeUrl = _storeUrlForPlatform(payload);
    final extra = payload.message?.trim();
    final versionLine = payload.latestVersion != null && payload.latestVersion!.isNotEmpty
        ? '\n\nLatest: ${payload.latestVersion} (build ${payload.latestBuild})\n'
            'Yours: $currentVersion (build $currentBuild)'
        : '\n\nLatest build: ${payload.latestBuild}\nYours: $currentBuild';

    await showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update available'),
          content: SingleChildScrollView(
            child: Text(
              '${extra != null && extra.isNotEmpty ? '$extra\n\n' : ''}$_defaultBody$versionLine',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final now = DateTime.now().millisecondsSinceEpoch;
                await prefs.setInt(_kDismissedLatestBuild, payload.latestBuild);
                await prefs.setInt(
                  _kSnoozeUntilMs,
                  now + _snooze.inMilliseconds,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                if (storeUrl == null) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Store link is not available yet.')),
                    );
                  }
                  return;
                }
                try {
                  final Uri? uri = Platform.isIOS
                      ? _iosLaunchUriForStoreUrl(storeUrl)
                      : Uri.tryParse(storeUrl.trim());
                  if (uri == null || !uri.hasScheme) {
                    debugPrint('AppUpdatePrompt: invalid store URL: $storeUrl');
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Store link is invalid.')),
                      );
                    }
                    return;
                  }
                  debugPrint('AppUpdatePrompt: launching $uri');
                  final ok = await _launchStoreUri(uri);
                  if (!ok && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Could not open the store.')),
                    );
                  }
                } catch (e) {
                  debugPrint('AppUpdatePrompt launchUrl: $e');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Could not open the store.')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
