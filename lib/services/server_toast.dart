import 'package:flutter/material.dart';

import '/flutter_flow/nav/nav.dart';
import '/services/app_toast.dart';

class ServerToast {
  static const String message =
      "Our servers are taking a quick nap. We'll have them back up soon!";

  static void show() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    AppToast.info(ctx, message);
  }

  static void showIf(bool condition) {
    if (condition) show();
  }
}

