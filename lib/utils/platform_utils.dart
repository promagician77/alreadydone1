// Platform checks. Use isIOS for App Store–only features (e.g. RevenueCat).

import 'platform_utils_stub.dart' if (dart.library.io) 'platform_utils_io.dart' as impl;

bool get isIOS => impl.isIOS;
