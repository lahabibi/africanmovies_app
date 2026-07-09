import 'package:flutter/services.dart';

class AppOrientation {
  AppOrientation._();

  static Future<void> lockPortrait() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  static Future<void> lockLandscape() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
