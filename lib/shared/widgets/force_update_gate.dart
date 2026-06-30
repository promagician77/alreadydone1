import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/network/backend_client.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  bool _updateRequired = false;
  MobileAppUpdatePayload? _payload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns (e.g. came back from the store).
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (kIsWeb) return;
    try {
      final payload = await BackendClient.fetchMobileAppUpdateInfo();
      if (payload == null) {
        // Backend disabled or unreachable — never lock the user out.
        if (mounted && _updateRequired) {
          setState(() => _updateRequired = false);
        }
        return;
      }

      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim());
      final required = _needsUpdate(
            currentBuild: currentBuild,
            currentVersion: info.version,
            latestBuild: payload.latestBuild,
            latestVersion: payload.latestVersion,
          ) &&
          _storeUrlFor(payload) != null;

      if (!mounted) return;
      setState(() {
        _updateRequired = required;
        _payload = payload;
      });
    } catch (e) {
      debugPrint('ForceUpdateGate: check failed: $e');
    }
  }

  /// Mirrors the backend `_needs_update` logic (version first, then build) so the
  /// client and server agree on what "out of date" means.
  static bool _needsUpdate({
    required int? currentBuild,
    required String? currentVersion,
    required int latestBuild,
    required String? latestVersion,
  }) {
    final hasCurrentVersion =
        currentVersion != null && currentVersion.trim().isNotEmpty;
    final hasLatestVersion =
        latestVersion != null && latestVersion.trim().isNotEmpty;

    if (hasCurrentVersion && hasLatestVersion) {
      final cmp = _compareVersions(
        _parseVersion(currentVersion),
        _parseVersion(latestVersion),
      );
      if (cmp > 0) return false; // ahead of latest (dev/TestFlight build)
      if (cmp < 0) return true; // behind latest
    }

    if (currentBuild != null && latestBuild > 0) {
      return currentBuild < latestBuild;
    }
    return false;
  }

  static List<int> _parseVersion(String v) =>
      v.trim().split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();

  static int _compareVersions(List<int> a, List<int> b) {
    final n = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai < bi ? -1 : 1;
    }
    return 0;
  }

  /// Play Store listing used when the backend doesn't supply an Android URL.
  static const String _defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.alreadydone.myapp';

  String? _storeUrlFor(MobileAppUpdatePayload payload) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      // On Android always send the user to the Play Store, preferring the
      // backend-provided URL and falling back to the known listing.
      final android = payload.androidStoreUrl?.trim();
      return (android != null && android.isNotEmpty)
          ? android
          : _defaultAndroidStoreUrl;
    }

    // iOS (and any other non-Android platform): prefer the App Store URL.
    final ios = payload.iosStoreUrl?.trim();
    if (ios != null && ios.isNotEmpty) return ios;
    final android = payload.androidStoreUrl?.trim();
    if (android != null && android.isNotEmpty) return android;
    return null;
  }

  Future<void> _openStore() async {
    final payload = _payload;
    if (payload == null) return;
    final url = _storeUrlFor(payload);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ForceUpdateGate: could not open store url $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_updateRequired) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        _UpdateRequiredScreen(
          message: _payload?.message,
          onUpdate: _openStore,
        ),
      ],
    );
  }
}

class _UpdateRequiredScreen extends StatelessWidget {
  const _UpdateRequiredScreen({required this.onUpdate, this.message});

  final VoidCallback onUpdate;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = (message != null && message!.trim().isNotEmpty)
        ? message!.trim()
        : 'A new version of Already Done is available. '
            'Please update to keep using the app.';

    return Material(
      color: const Color(0xFFFEFDFB),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update,
                    size: 64,
                    color: Color(0xFFB8861E),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF57534E),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onUpdate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB8861E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
