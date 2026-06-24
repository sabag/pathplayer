import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Device/app metadata sent to Jellyfin in the `Authorization` header.
class DeviceAuthInfo {
  const DeviceAuthInfo({
    required this.deviceName,
    required this.clientVersion,
  });

  /// Human-readable device name shown in the Jellyfin sessions list.
  final String deviceName;

  /// App version shown in the Jellyfin sessions list.
  final String clientVersion;
}

/// Reads the app version and device model/name once and caches the result.
class DeviceInfoService {
  static DeviceAuthInfo? _cached;

  static Future<DeviceAuthInfo> getInfo() async {
    if (_cached != null) return _cached!;

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceName = await _readDeviceName();

    _cached = DeviceAuthInfo(
      deviceName: deviceName,
      clientVersion: packageInfo.version,
    );
    return _cached!;
  }

  static Future<String> _readDeviceName() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return info.model;
    }

    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return info.utsname.machine ?? info.model ?? 'iOS';
    }

    if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      return info.computerName;
    }

    if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      return info.computerName;
    }

    if (Platform.isLinux) {
      final info = await plugin.linuxInfo;
      return info.prettyName;
    }

    return 'Unknown';
  }
}
