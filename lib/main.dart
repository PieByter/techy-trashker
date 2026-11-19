import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/google_maps_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF7F6F1),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Mulai load script Maps di background (web). MapScreen memakai future yang
  // sama dan menampilkan preview sampai script siap.
  GoogleMapsConfig.prepare();

  runApp(const TechyTrashkerApp());
}
