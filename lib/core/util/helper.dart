import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

extension StringExtensions on String {
  void logType() {
    devPrint(runtimeType);
  }

  void log() {
    devPrint(this);
  }

  /// Returns the debug value if debug mode is enabled, otherwise returns the original value
  String debugValue(String? val) {
    if (kDebugMode) {
      return val ?? this;
    } else {
      return this;
    }
  }
}

void devPrint(var message) {
  if (kDebugMode) {
    print(message);
  }
}

// Helper method to detect mobile devices
bool isMobile(BuildContext context) {
  // Use screen width to detect mobile devices
  // This works well for both native mobile and mobile browsers
  return MediaQuery.of(context).size.width < 600;
}
