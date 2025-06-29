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

  /// Get appropriate font sizes for different screen types with proportional scaling
  Map<String, double> getFontSizes(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = getDeviceType(context);
    final isCompact = isCompactScreen(context);
    
    // Use the smaller dimension as base for consistent scaling
    final baseDimension = size.width < size.height ? size.width : size.height;
    
    // Calculate scale factor based on device type and screen size
    double scaleFactor;
    switch (deviceType) {
      case DeviceType.phone:
        scaleFactor = baseDimension / (isCompact ? 400.0 : 360.0); // Base reference size for phones
        break;
      case DeviceType.tablet:
        scaleFactor = baseDimension / 768.0; // Base reference size for tablets
        break;
      case DeviceType.desktop:
        // For desktop, use a more generous scaling to keep text readable
        scaleFactor = (baseDimension / 800.0).clamp(1.2, 2.0); // Ensure desktop text is never too small
        break;
    }
    
    // Clamp scale factor to reasonable bounds (but allow desktop to be larger)
    scaleFactor = deviceType == DeviceType.desktop 
        ? scaleFactor.clamp(1.2, 2.5) 
        : scaleFactor.clamp(0.7, 2.0);
    
    // Base font sizes that will be scaled
    final baseFontSizes = {
      'title': 24.0,
      'subtitle': 16.0,
      'body': 12.0,
      'caption': 10.0,
      'gameOver': 48.0,
      'pause': 48.0,
      'score': 20.0,
      'instructions': 12.0,
      'header': 28.0,
    };
    
    // Apply scaling and device-specific adjustments
    final scaledSizes = <String, double>{};
    baseFontSizes.forEach((key, baseSize) {
      double scaledSize = baseSize * scaleFactor;
      
      // Apply minimum and maximum constraints for readability
      // Use higher minimums for desktop
      final isDesktop = deviceType == DeviceType.desktop;
      switch (key) {
        case 'title':
          scaledSize = scaledSize.clamp(isDesktop ? 24.0 : 18.0, 48.0);
          break;
        case 'subtitle':
          scaledSize = scaledSize.clamp(isDesktop ? 16.0 : 12.0, 32.0);
          break;
        case 'body':
          scaledSize = scaledSize.clamp(isDesktop ? 12.0 : 8.0, 24.0);
          break;
        case 'caption':
          scaledSize = scaledSize.clamp(isDesktop ? 10.0 : 6.0, 18.0);
          break;
        case 'gameOver':
          scaledSize = scaledSize.clamp(isDesktop ? 48.0 : 32.0, 96.0);
          break;
        case 'pause':
          scaledSize = scaledSize.clamp(isDesktop ? 48.0 : 32.0, 96.0);
          break;
        case 'score':
          scaledSize = scaledSize.clamp(isDesktop ? 20.0 : 14.0, 40.0);
          break;
        case 'instructions':
          scaledSize = scaledSize.clamp(isDesktop ? 12.0 : 8.0, 24.0);
          break;
        case 'header':
          scaledSize = scaledSize.clamp(isDesktop ? 28.0 : 20.0, 56.0);
          break;
      }
      
      scaledSizes[key] = scaledSize;
    });
    
    // Additional adjustments for compact screens
    if (isCompact && deviceType == DeviceType.phone) {
      scaledSizes.forEach((key, value) {
        scaledSizes[key] = value * 0.9; // Slightly reduce for very compact screens
      });
    }
    
    return scaledSizes;
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
    
    // Calculate responsive positioning based on screen dimensions
    final topMargin = size.height * 0.015; // 1.5% of screen height
    final sideMargin = size.width * 0.02; // 2% of screen width
    final bottomMargin = size.height * 0.02; // 2% of screen height
    
    // Phone portrait: stack panels vertically, minimize overlap
    if (deviceType == DeviceType.phone && orientation == ScreenOrientation.portrait) {
      final scoreHeight = size.height * (isCompact ? 0.08 : 0.12); // 8-12% of screen height
      final bottomAreaHeight = size.height * (isCompact ? 0.25 : 0.3); // 25-30% for bottom controls
      
      return {
        'scorePosition': {'top': topMargin, 'left': sideMargin},
        'objectivesPosition': {'top': topMargin + scoreHeight + (size.height * 0.01), 'left': sideMargin}, // Stack below score with 1% gap
        'controlsPosition': {'bottom': bottomAreaHeight, 'left': sideMargin},
        'bottomControlsPosition': {'bottom': bottomMargin, 'right': sideMargin},
        'instructionsVisible': false, // Always hide in portrait phone mode
        'instructionsPosition': {'bottom': size.height * 0.1, 'center': true},
        'headerVisible': false, // Always hide in phone mode
        'showCompactUI': true, // Always compact on phone
        'panelMaxWidth': size.width * 0.9, // Almost full width since stacking vertically
      };
    }
    
    // Phone landscape: horizontal layout, more space
    if (deviceType == DeviceType.phone && orientation == ScreenOrientation.landscape) {
      return {
        'scorePosition': {'top': topMargin, 'left': sideMargin},
        'objectivesPosition': {'top': topMargin, 'right': sideMargin},
        'controlsPosition': {'bottom': size.height * 0.15, 'left': sideMargin}, // 15% from bottom
        'bottomControlsPosition': {'bottom': bottomMargin, 'right': sideMargin},
        'instructionsVisible': false, // Hidden in landscape to save space
        'headerVisible': false, // Hidden in landscape
        'showCompactUI': true,
        'panelMaxWidth': size.width * 0.25, // Much smaller to ensure no overlap
      };
    }
    
    // Tablet: more space, standard layout
    if (deviceType == DeviceType.tablet) {
      return {
        'scorePosition': {'top': topMargin, 'left': sideMargin},
        'objectivesPosition': {'top': topMargin, 'right': sideMargin},
        'controlsPosition': {'bottom': size.height * 0.08, 'left': sideMargin}, // 8% from bottom
        'bottomControlsPosition': {'bottom': bottomMargin * 1.5, 'right': sideMargin * 1.5},
        'instructionsVisible': true,
        'instructionsPosition': {'bottom': bottomMargin * 1.5, 'center': true},
        'headerVisible': true,
        'showCompactUI': false,
        'panelMaxWidth': size.width * 0.25,
      };
    }
    
    // Desktop: full layout with responsive positioning
    return {
      'scorePosition': {'top': topMargin, 'left': sideMargin},
      'objectivesPosition': {'top': topMargin, 'right': sideMargin},
      'controlsPosition': {'bottom': size.height * 0.06, 'left': sideMargin}, // 6% from bottom
      'bottomControlsPosition': {'bottom': bottomMargin * 1.5, 'right': sideMargin * 1.5},
      'instructionsVisible': true,
      'instructionsPosition': {'bottom': bottomMargin * 1.5, 'center': true},
      'headerVisible': true,
      'showCompactUI': false,
      'panelMaxWidth': size.width > 1200 ? 350.0 : (size.width * 0.28), // Responsive max width
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

  /// Get responsive TextStyle for different text types
  TextStyle getTextStyle(BuildContext context, String textType, {Color? color, FontWeight? fontWeight}) {
    final fontSizes = getFontSizes(context);
    final fontSize = fontSizes[textType] ?? fontSizes['body']!;
    
    return TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.white,
      fontWeight: fontWeight ?? FontWeight.normal,
      shadows: textType == 'gameOver' || textType == 'pause' || textType == 'header'
          ? [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withValues(alpha: 0.7),
                offset: const Offset(2.0, 2.0),
              ),
            ]
          : null,
    );
  }

  /// Get responsive icon size
  double getIconSize(BuildContext context, {String type = 'default'}) {
    final size = MediaQuery.of(context).size;
    
    // Base icon size relative to screen width
    final baseSize = size.width * 0.08; // 8% of screen width
    
    switch (type) {
      case 'small':
        return (baseSize * 0.6).clamp(16.0, 32.0);
      case 'large':
        return (baseSize * 1.5).clamp(32.0, 64.0);
      default:
        return baseSize.clamp(24.0, 48.0);
    }
  }
}
