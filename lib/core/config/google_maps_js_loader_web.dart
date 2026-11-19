import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('__techyMapsReady')
external set _techyMapsReadyCallback(JSFunction callback);

/// Memuat Google Maps JavaScript API dengan key yang berasal dari
/// `--dart-define-from-file=.env`.
///
/// Memakai callback resmi `loading=async` (bukan event `load`) karena event
/// `load` bisa selesai sebelum namespace seperti `google.maps.MapTypeId` siap.
Future<void> loadGoogleMapsJs(String apiKey) async {
  if (apiKey.isEmpty) return;

  final existing = web.document.querySelector(
    'script[data-techy-google-maps="true"]',
  );
  if (existing != null) return;

  final completer = Completer<void>();
  _techyMapsReadyCallback = ((JSAny? _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;

  final script = web.HTMLScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}&loading=async&callback=__techyMapsReady'
    ..async = true;
  script.setAttribute('data-techy-google-maps', 'true');
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Gagal memuat Google Maps JavaScript API.'),
        );
      }
    }).toJS,
  );

  web.document.head!.append(script);

  await completer.future.timeout(const Duration(seconds: 12));
}
