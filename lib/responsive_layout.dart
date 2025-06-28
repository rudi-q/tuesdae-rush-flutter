import 'package:flutter/material.dart';
import 'mobile_manager.dart';

enum DeviceType { phone, tablet, desktop }
enum ScreenOrientation { portrait, landscape }

class ResponsiveLayout {
  static ResponsiveLayout? _instance;
  
  ResponsiveLayout._();
  
  static ResponsiveLayout get instance {
    _instance ??= ResponsiveLayout._();
    return _instance!;
  }

  DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    if (!MobileManager().isMobile) {
      return DeviceType.desktop;
    }
    
    if (MobileManager().isTablet(width, height)) {
      return DeviceType.tablet;
    }
    
    return DeviceType.phone;
  }

  ScreenOrientation getOrientation(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait 
        ? ScreenOrientation.portrait 
        : ScreenOrientation.landscape;
  }

  bool isCompactScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minDimension = size.width < size.height ? size.width : size.height;
    return minDimension < 600;
  }

  /// Get appropriate font sizes for different screen types
  Map<String, double> getFontSizes(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isCompact = isCompactScreen(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return {
          'title': isCompact ? 20.0 : 24.0,
          'subtitle': isCompact ? 14.0 : 16.0,
          'body': isCompact ? 10.0 : 12.0,
          'caption': isCompact ? 8.0 : 10.0,
          'gameOver': isCompact ? 36.0 : 48.0,
          'pause': isCompact ? 36.0 : 48.0,
          'score': isCompact ? 16.0 : 20.0,
        };
      case DeviceType.tablet:
        return {
          'title': 28.0,
          'subtitle': 18.0,
          'body': 14.0,
          'caption': 12.0,
          'gameOver': 56.0,
          'pause': 56.0,
          'score': 24.0,
        };
      case DeviceType.desktop:
        return {
          'title': 24.0,
          'subtitle': 16.0,
          'body': 12.0,
          'caption': 10.0,
          'gameOver': 48.0,
          'pause': 48.0,
          'score': 20.0,
        };
    }
  }

  /// Get appropriate padding for different screen types
  EdgeInsets getPadding(BuildContext context, {String type = 'default'}) {
    final deviceType = getDeviceType(context);
    final isCompact = isCompactScreen(context);
    
    switch (type) {
      case 'panel':
        switch (deviceType) {
          case DeviceType.phone:
            return EdgeInsets.all(isCompact ? 8.0 : 12.0);
          case DeviceType.tablet:
            return EdgeInsets.all(16.0);
          case DeviceType.desktop:
            return EdgeInsets.all(12.0);
        }
      case 'button':
        switch (deviceType) {
          case DeviceType.phone:
            return EdgeInsets.all(isCompact ? 6.0 : 8.0);
          case DeviceType.tablet:
            return EdgeInsets.all(12.0);
          case DeviceType.desktop:
            return EdgeInsets.all(8.0);
        }
      default:
        switch (deviceType) {
          case DeviceType.phone:
            return EdgeInsets.all(isCompact ? 4.0 : 8.0);
          case DeviceType.tablet:
            return EdgeInsets.all(12.0);
          case DeviceType.desktop:
            return EdgeInsets.all(10.0);
        }
    }
  }

  /// Get appropriate UI element positions for mobile
  Map<String, dynamic> getUILayout(BuildContext context) {
    final deviceType = getDeviceType(context);
    final orientation = getOrientation(context);
    final isCompact = isCompactScreen(context);
    final size = MediaQuery.of(context).size;
    
    // Phone portrait: stack panels vertically, minimize overlap
    if (deviceType == DeviceType.phone && orientation == ScreenOrientation.portrait) {
      return {
        'scorePosition': {'top': 10.0, 'left': 10.0},
        'objectivesPosition': {'top': 10.0, 'right': 10.0},
        'controlsPosition': {'bottom': isCompact ? 80.0 : 100.0, 'left': 10.0},
        'bottomControlsPosition': {'bottom': 10.0, 'right': 10.0},
        'instructionsVisible': !isCompact,
        'instructionsPosition': {'bottom': isCompact ? 50.0 : 60.0, 'center': true},
        'headerVisible': !isCompact,
        'showCompactUI': isCompact,
        'panelMaxWidth': size.width * 0.45,
      };
    }
    
    // Phone landscape: horizontal layout, more space
    if (deviceType == DeviceType.phone && orientation == ScreenOrientation.landscape) {
      return {
        'scorePosition': {'top': 10.0, 'left': 10.0},
        'objectivesPosition': {'top': 10.0, 'right': 10.0},
        'controlsPosition': {'bottom': 10.0, 'left': 10.0},
        'bottomControlsPosition': {'bottom': 10.0, 'right': 10.0},
        'instructionsVisible': false, // Hidden in landscape to save space
        'headerVisible': false, // Hidden in landscape
        'showCompactUI': true,
        'panelMaxWidth': size.width * 0.3,
      };
    }
    
    // Tablet: more space, standard layout
    if (deviceType == DeviceType.tablet) {
      return {
        'scorePosition': {'top': 10.0, 'left': 10.0},
        'objectivesPosition': {'top': 10.0, 'right': 10.0},
        'controlsPosition': {'bottom': 10.0, 'left': 10.0},
        'bottomControlsPosition': {'bottom': 20.0, 'right': 20.0},
        'instructionsVisible': true,
        'instructionsPosition': {'bottom': 20.0, 'center': true},
        'headerVisible': true,
        'showCompactUI': false,
        'panelMaxWidth': size.width * 0.25,
      };
    }
    
    // Desktop: full layout
    return {
      'scorePosition': {'top': 10.0, 'left': 10.0},
      'objectivesPosition': {'top': 10.0, 'right': 10.0},
      'controlsPosition': {'bottom': 10.0, 'left': 10.0},
      'bottomControlsPosition': {'bottom': 20.0, 'right': 20.0},
      'instructionsVisible': true,
      'instructionsPosition': {'bottom': 20.0, 'center': true},
      'headerVisible': true,
      'showCompactUI': false,
      'panelMaxWidth': 300.0,
    };
  }

  /// Get appropriate panel opacity for readability
  double getPanelOpacity(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return 0.8; // Higher opacity for better readability on small screens
      case DeviceType.tablet:
        return 0.7;
      case DeviceType.desktop:
        return 0.6;
    }
  }

  /// Get button size for touch targets
  double getButtonSize(BuildContext context) {
    return MobileManager().getTouchTargetSize(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
  }

  /// Check if UI should be simplified for performance
  bool shouldSimplifyUI(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isCompact = isCompactScreen(context);
    
    return deviceType == DeviceType.phone && isCompact;
  }

  /// Get spacing between UI elements
  double getSpacing(BuildContext context, {String type = 'default'}) {
    final deviceType = getDeviceType(context);
    final isCompact = isCompactScreen(context);
    
    switch (type) {
      case 'large':
        return deviceType == DeviceType.phone ? (isCompact ? 16.0 : 20.0) : 24.0;
      case 'medium':
        return deviceType == DeviceType.phone ? (isCompact ? 8.0 : 12.0) : 16.0;
      case 'small':
        return deviceType == DeviceType.phone ? (isCompact ? 4.0 : 6.0) : 8.0;
      default:
        return deviceType == DeviceType.phone ? (isCompact ? 6.0 : 10.0) : 12.0;
    }
  }
}
