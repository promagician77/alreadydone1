import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Persists a stable device id in secure storage (iOS Keychain / Android encrypted prefs).
///
/// Survives typical uninstall + reinstall; not guaranteed across factory reset or device swap.
class PersistentDeviceIdService {
  PersistentDeviceIdService._();

  static const _kDeviceIdKey = 'persistent_device_id';

  /// Known bogus ANDROID_ID shared by many OEM ROMs.
  static const _fakeAndroidId = '9774d56d682e549c';

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Future<String?> getIosPersistentDeviceId() async {
    try {
      final storedId = await _secureStorage.read(key: _kDeviceIdKey);
      if (storedId != null && storedId.trim().isNotEmpty) {
        return storedId.trim();
      }

      final info = await _deviceInfo.iosInfo;
      final vendorId = info.identifierForVendor?.trim();
      final id = (vendorId != null && vendorId.isNotEmpty)
          ? vendorId
          : const Uuid().v4();

      await _secureStorage.write(key: _kDeviceIdKey, value: id);
      return id;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAndroidPersistentDeviceId() async {
    try {
      final storedId = await _secureStorage.read(key: _kDeviceIdKey);
      if (storedId != null && storedId.trim().isNotEmpty) {
        return storedId.trim();
      }

      final info = await _deviceInfo.androidInfo;
      final map = info.data;
      final androidId = (map['androidId'] as String?)?.trim() ?? '';

      final picked = (androidId.isNotEmpty && androidId != _fakeAndroidId)
          ? androidId
          : info.id.trim();

      final id = picked.isNotEmpty ? picked : const Uuid().v4();

      await _secureStorage.write(key: _kDeviceIdKey, value: id);
      return id;
    } catch (_) {
      return null;
    }
  }
}
