// IO implementation: used when dart:io is available (iOS, Android).

import 'dart:io' show Platform;

bool get isIOS => Platform.isIOS;
bool get isAndroid => Platform.isAndroid;
