import 'package:flutter/foundation.dart';

class ApiConfig {
  static String customBaseUrl = '';

  static String get defaultBaseUrl {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3001';
    }
    // Default to host machine Wi-Fi IP for physical phones & emulators
    return 'http://172.19.25.190:3001';
  }
}
