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
import '/utils/app_release_compare.dart';

class AppUpdatePromptService {
  AppUpdatePromptService._();

  static const _kSnoozeUntilMs = 'app_update_snooze_until_ms';
  static const _kDismissedLatestBuild = 'app_update_dismissed_latest_build';
  static const _kDismissedFingerprint = 'app_update_dismissed_fingerprint';
  static const _androidPackageId = 'com.mycompany.alreadyapp';

  static const Duration _snooze = Duration(days: 3);

  static const _defaultBody =
      'A new version of Already Done is available. Update for the latest improvements.';

  static OverlayEntry? _overlayEntry;
  static bool get _isShowing => _overlayEntry != null;

  static Future<void> checkAndMaybeShow() async {
    if (kIsWeb) return;

    late final int currentBuild;
    late final String currentVersion;
    try {
      final pkg = await PackageInfo.fromPlatform();
      debugPrint('AppUpdatePrompt: pkg: $pkg');
      currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      debugPrint('AppUpdatePrompt: currentBuild: $currentBuild');
      currentVersion = pkg.version;
    } catch (e) {
      debugPrint('AppUpdatePrompt: PackageInfo failed: $e');
      return;
    }

    final payload = await BackendClient.fetchMobileAppUpdateInfo();
    debugPrint('AppUpdatePrompt: payload: $payload');

    if (payload == null) return;
    if (!isRemoteAppReleaseNewer(
      latestVersion: payload.latestVersion,
      latestBuild: payload.latestBuild,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    )) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!_shouldShowAfterSnooze(prefs, payload)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showDialog(
        prefs: prefs,
        payload: payload,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ));
    });
  }

  static bool _shouldShowAfterSnooze(
    SharedPreferences prefs,
    MobileAppUpdatePayload payload,
  ) {
    final snoozeUntil = prefs.getInt(_kSnoozeUntilMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= snoozeUntil) return true;

    final lv = payload.latestVersion?.trim();
    final hasSemver = lv != null && lv.isNotEmpty;
    if (hasSemver) {
      final sig = prefs.getString(_kDismissedFingerprint);
      if (sig != null && sig.isNotEmpty) {
        return isRemoteNewerThanFingerprint(
          latestVersion: payload.latestVersion,
          latestBuild: payload.latestBuild,
          dismissedFingerprint: sig,
        );
      }
      final legacy = prefs.getInt(_kDismissedLatestBuild);
      if (legacy != null) {
        return payload.latestBuild > legacy;
      }
      return true;
    }

    final dismissedFor = prefs.getInt(_kDismissedLatestBuild) ?? -1;
    return payload.latestBuild > dismissedFor;
  }

  /// Stored when the user taps Later (must match backend ordering: version then build).
  static String _dismissFingerprint(MobileAppUpdatePayload p) {
    final plus = p.latestVersionPlus?.trim();
    if (plus != null && plus.isNotEmpty) return plus;
    final v = p.latestVersion?.trim();
    if (v != null && v.isNotEmpty) {
      if (p.latestBuild > 0) return '$v+${p.latestBuild}';
      return v;
    }
    return '';
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

  /// iOS: try App Store app (`itms-apps`) first, then HTTPS (Safari). Simulator has no App Store — HTTPS fallback is required.
  static Future<bool> _launchStoreUriIos(String storeUrl) async {
    final trimmed = storeUrl.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme) {
      debugPrint('AppUpdatePrompt: iOS invalid store URL');
      return false;
    }

    Uri? itmsUri;
    late Uri httpsUri;

    if (parsed.scheme == 'https' || parsed.scheme == 'http') {
      httpsUri = parsed;
      final host = parsed.host.toLowerCase();
      if (host.contains('apps.apple.com') || host.contains('itunes.apple.com')) {
        final idMatch = RegExp(r'/id(\d+)').firstMatch(parsed.path);
        if (idMatch != null) {
          itmsUri = Uri.parse('itms-apps://apps.apple.com/app/id${idMatch.group(1)}');
        }
      }
    } else if (parsed.scheme == 'itms-apps' || parsed.scheme == 'itms') {
      itmsUri = parsed;
      final idMatch = RegExp(r'/id(\d+)').firstMatch(parsed.path);
      httpsUri = idMatch != null
          ? Uri.parse('https://apps.apple.com/app/id${idMatch.group(1)}')
          : Uri.parse(trimmed.replaceFirst(RegExp(r'^itms-apps'), 'https'));
    } else {
      httpsUri = parsed;
    }

    Future<bool> tryOpen(Uri u, LaunchMode mode) async {
      try {
        final ok = await launchUrl(u, mode: mode);
        if (ok) {
          debugPrint('AppUpdatePrompt: opened $u ($mode)');
        }
        return ok;
      } catch (e) {
        debugPrint('AppUpdatePrompt: launch error $u ($mode): $e');
        return false;
      }
    }

    if (itmsUri != null) {
      if (await tryOpen(itmsUri, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
      if (await tryOpen(itmsUri, LaunchMode.platformDefault)) {
        return true;
      }
      debugPrint('AppUpdatePrompt: itms failed (normal on Simulator), trying https $httpsUri');
    }

    if (await tryOpen(httpsUri, LaunchMode.platformDefault)) {
      return true;
    }
    if (await tryOpen(httpsUri, LaunchMode.externalApplication)) {
      return true;
    }
    return false;
  }

  static Future<bool> _launchStoreUriAndroid(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl.trim());
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _showDialog({
    required SharedPreferences prefs,
    required MobileAppUpdatePayload payload,
    required String currentVersion,
    required int currentBuild,
  }) async {
    if (_isShowing) return;

    final overlayState = appNavigatorKey.currentState?.overlay;
    final overlayContext = overlayState?.context;
    if (overlayState == null || overlayContext == null || !overlayContext.mounted) {
      return;
    }

    final storeUrl = _storeUrlForPlatform(payload);
    final extra = payload.message?.trim();

    final intro = (extra != null && extra.isNotEmpty)
        ? '$extra\n\n$_defaultBody'
        : _defaultBody;
    final latestLabel = (payload.latestVersionPlus != null &&
            payload.latestVersionPlus!.trim().isNotEmpty)
        ? payload.latestVersionPlus!.trim()
        : (payload.latestVersion != null && payload.latestVersion!.isNotEmpty)
            ? (payload.latestBuild > 0
                ? '${payload.latestVersion}+${payload.latestBuild}'
                : payload.latestVersion!)
            : 'build ${payload.latestBuild}';
    final yoursLabel = currentBuild > 0
        ? '$currentVersion+$currentBuild'
        : currentVersion;
    final versionSummary = (payload.latestVersion != null &&
            payload.latestVersion!.isNotEmpty)
        ? 'Latest: $latestLabel\nYours: $yoursLabel'
        : 'Latest build: ${payload.latestBuild}\nYours: $currentBuild';

    // Use an OverlayEntry so navigation (e.g. splash -> login redirect) doesn't dismiss it.
    final controller = AnimationController(
      vsync: overlayState,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    void close() {
      final entry = _overlayEntry;
      if (entry == null) return;
      unawaited(() async {
        try {
          await controller.reverse();
        } catch (_) {}
        controller.dispose();
        entry.remove();
        _overlayEntry = null;
      }());
    }

    Future<void> onLater() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fp = _dismissFingerprint(payload);
      if (fp.isNotEmpty) {
        await prefs.setString(_kDismissedFingerprint, fp);
        await prefs.remove(_kDismissedLatestBuild);
      } else {
        await prefs.setInt(_kDismissedLatestBuild, payload.latestBuild);
        await prefs.remove(_kDismissedFingerprint);
      }
      await prefs.setInt(_kSnoozeUntilMs, now + _snooze.inMilliseconds);
      close();
    }

    Future<void> onUpdate() async {
      if (storeUrl == null) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
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
        final ok = Platform.isIOS
            ? await _launchStoreUriIos(storeUrl)
            : await _launchStoreUriAndroid(storeUrl);
        if (!ok) {
          debugPrint('AppUpdatePrompt: all launch attempts failed for $storeUrl');
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
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
      } catch (e) {
        debugPrint('AppUpdatePrompt launchUrl: $e');
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
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

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: FadeTransition(
            opacity: curved,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: close,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(24)),
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
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(24),
                                ),
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
                                        color: AuthTheme.gold
                                            .withValues(alpha: 0.28),
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
              ],
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    controller.forward();
  }
}
