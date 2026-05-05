import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
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

    final intro = (extra != null && extra.isNotEmpty)
        ? '$extra\n\n$_defaultBody'
        : _defaultBody;
    final versionSummary = (payload.latestVersion != null &&
            payload.latestVersion!.isNotEmpty)
        ? 'Latest: ${payload.latestVersion} (build ${payload.latestBuild})\n'
            'Yours: $currentVersion (build $currentBuild)'
        : 'Latest build: ${payload.latestBuild}\nYours: $currentBuild';

    await showGeneralDialog<void>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(ctx).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        Future<void> onLater() async {
          final now = DateTime.now().millisecondsSinceEpoch;
          await prefs.setInt(_kDismissedLatestBuild, payload.latestBuild);
          await prefs.setInt(_kSnoozeUntilMs, now + _snooze.inMilliseconds);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        }

        Future<void> onUpdate() async {
          if (storeUrl == null) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  backgroundColor: AuthTheme.ink,
                  content: Text(
                    'Store link is not available yet.',
                    style: GoogleFonts.outfit(color: AuthTheme.surface),
                  ),
                ),
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
                  SnackBar(
                    backgroundColor: AuthTheme.ink,
                    content: Text(
                      'Store link is invalid.',
                      style: GoogleFonts.outfit(color: AuthTheme.surface),
                    ),
                  ),
                );
              }
              return;
            }
            debugPrint('AppUpdatePrompt: launching $uri');
            final ok = await _launchStoreUri(uri);
            if (!ok && dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  backgroundColor: AuthTheme.ink,
                  content: Text(
                    'Could not open the store.',
                    style: GoogleFonts.outfit(color: AuthTheme.surface),
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('AppUpdatePrompt launchUrl: $e');
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  backgroundColor: AuthTheme.ink,
                  content: Text(
                    'Could not open the store.',
                    style: GoogleFonts.outfit(color: AuthTheme.surface),
                  ),
                ),
              );
            }
          }
        }

        return FadeTransition(
          opacity: curved,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: AuthTheme.ink.withValues(alpha: 0.42),
                  ),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                  child: GestureDetector(
                    onTap: () {},
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                color: AuthTheme.gold.withValues(alpha: 0.22),
                                blurRadius: 36,
                                spreadRadius: -6,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AuthTheme.ink.withValues(alpha: 0.14),
                                blurRadius: 48,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(24)),
                                color: AuthTheme.surface,
                                border: Border.all(
                                  color: AuthTheme.gold.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AuthTheme.goldPale,
                                      border: Border.all(
                                        color:
                                            AuthTheme.gold.withValues(alpha: 0.28),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AuthTheme.gold
                                              .withValues(alpha: 0.18),
                                          blurRadius: 16,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.system_update_rounded,
                                      size: 30,
                                      color: AuthTheme.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Update available',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AuthTheme.ink,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    intro,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      height: 1.55,
                                      color: AuthTheme.inkSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AuthTheme.goldPale,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                      border: Border.all(
                                        color: AuthTheme.gold
                                            .withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: Text(
                                      versionSummary,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        height: 1.45,
                                        fontWeight: FontWeight.w500,
                                        color: AuthTheme.inkMid,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AuthTheme.inkSoft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: onLater,
                                        child: Text(
                                          'Later',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AuthTheme.gold,
                                          foregroundColor: AuthTheme.surface,
                                          disabledBackgroundColor:
                                              AuthTheme.stoneMid,
                                          elevation: 0,
                                          shadowColor: AuthTheme.gold
                                              .withValues(alpha: 0.45),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 26,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: onUpdate,
                                        child: Text(
                                          'Update',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
