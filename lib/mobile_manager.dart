import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class MobileManager {
  static final MobileManager _instance = MobileManager._internal();
  factory MobileManager() => _instance;
  MobileManager._internal();

  bool _hapticsEnabled = true;
  bool _isVibrationSupported = false;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get isVibrationSupported => _isVibrationSupported;

  Future<void> initialize() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      _isVibrationSupported = hasVibrator ?? false;
    } catch (e) {
      debugPrint('Error checking vibration support: $e');
      _isVibrationSupported = false;
    }
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Light haptic feedback for traffic light toggles
  Future<void> lightHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.lightImpact();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      debugPrint('Error with light haptic: $e');
    }
  }

  /// Medium haptic feedback for game events
  Future<void> mediumHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.mediumImpact();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Error with medium haptic: $e');
    }
  }

  /// Heavy haptic feedback for crashes and errors
  Future<void> heavyHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.heavyImpact();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      debugPrint('Error with heavy haptic: $e');
    }
  }

  /// Success haptic pattern for achievements
  Future<void> successHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.mediumImpact();
        await Future.delayed(Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(pattern: [0, 100, 50, 50]);
      }
    } catch (e) {
      debugPrint('Error with success haptic: $e');
    }
  }

  /// Error haptic pattern for crashes
  Future<void> errorHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (e) {
      debugPrint('Error with error haptic: $e');
    }
  }

  /// Selection haptic for UI interactions
  Future<void> selectionHaptic() async {
    if (!_hapticsEnabled) return;
    
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HapticFeedback.selectionClick();
      } else if (defaultTargetPlatform == TargetPlatform.android && _isVibrationSupported) {
        await Vibration.vibrate(duration: 25);
      }
    } catch (e) {
      debugPrint('Error with selection haptic: $e');
    }
  }

  /// Check if device is mobile
  bool get isMobile {
    return defaultTargetPlatform == TargetPlatform.android || 
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Check if device is tablet (rough heuristic)
  bool isTablet(double screenWidth, double screenHeight) {
    if (!isMobile) return false;
    
    double minDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    double maxDimension = screenWidth > screenHeight ? screenWidth : screenHeight;
    
    // Consider tablets to have minimum dimension > 600 and aspect ratio < 2:1
    return minDimension > 600 && (maxDimension / minDimension) < 2.0;
  }

  /// Get appropriate touch target size for device
  double getTouchTargetSize(double screenWidth, double screenHeight) {
    if (!isMobile) return 80; // Desktop default
    
    double minDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    if (isTablet(screenWidth, screenHeight)) {
      // Tablet: larger touch targets
      return (minDimension * 0.08).clamp(80, 120);
    } else {
      // Phone: medium touch targets  
      return (minDimension * 0.12).clamp(80, 100);
    }
  }
}
