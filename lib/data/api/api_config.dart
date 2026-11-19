import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return 'http://localhost:3000';
    // Android emulator reaches the host machine via 10.0.2.2.
    // Override API_BASE_URL for iOS simulator or a physical device.
    return 'http://10.0.2.2:3000';
  }
}
