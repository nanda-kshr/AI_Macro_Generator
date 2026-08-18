import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Resolves the default backend base URL depending on platform.
  /// For Android emulator, uses 10.0.2.2; for web/desktop/iOS uses localhost.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 routes to host machine localhost from standard Android emulator
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }
}
