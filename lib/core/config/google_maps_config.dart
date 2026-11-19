import 'package:flutter/foundation.dart';

import 'google_maps_js_loader.dart';

/// Konfigurasi Google Maps.
///
/// Android/iOS memakai API key native yang di-inject saat build:
/// - Android: `android/app/build.gradle.kts` membaca `GOOGLE_MAPS_API_KEY`
///   dari `.env`.
/// - iOS: `ios/Flutter/Secrets.xcconfig` (lihat README).
/// - Web: API key dibaca dari `--dart-define-from-file=.env` lalu script
///   Google Maps JavaScript API dimuat sebelum GoogleMap dibuat.
abstract final class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool _ready = false;
  static Object? _loadError;
  static Future<void>? _prepareFuture;

  /// Native selalu siap. Web baru siap setelah script Maps selesai dimuat.
  static bool get isReady => !kIsWeb || _ready;

  static bool get isWebKeyMissing => kIsWeb && apiKey.isEmpty;

  static bool get hasWebLoadError => kIsWeb && _loadError != null;

  static Object? get loadError => _loadError;

  /// Aman dipanggil berkali-kali; future yang sama dikembalikan.
  static Future<void> prepare() {
    if (!kIsWeb || apiKey.isEmpty || _ready || _loadError != null) {
      return Future<void>.value();
    }

    return _prepareFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      await loadGoogleMapsJs(apiKey);
      _ready = true;
    } catch (error) {
      _loadError = error;
    }
  }
}
