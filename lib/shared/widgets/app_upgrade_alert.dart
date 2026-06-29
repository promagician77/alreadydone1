import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import '/flutter_flow/nav/nav.dart';
import '/shared/services/app_upgrader.dart';

class AppUpgradeAlert extends StatefulWidget {
  const AppUpgradeAlert({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpgradeAlert> createState() => _AppUpgradeAlertState();
}

class _AppUpgradeAlertState extends State<AppUpgradeAlert>
    with WidgetsBindingObserver {
  static const _splashGate = Duration(milliseconds: 2500);

  bool _pastSplashGate = false;
  Key _alertKey = UniqueKey();
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _splashTimer = Timer(_splashGate, () {
      if (!mounted) return;
      setState(() => _pastSplashGate = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pastSplashGate) {
      setState(() => _alertKey = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_pastSplashGate) {
      return widget.child;
    }

    final dialogStyle = !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.iOS
        ? UpgradeDialogStyle.cupertino
        : UpgradeDialogStyle.material;

    return UpgradeAlert(
      key: _alertKey,
      upgrader: appUpgrader,
      navigatorKey: appNavigatorKey,
      dialogStyle: dialogStyle,
      child: widget.child,
    );
  }
}
