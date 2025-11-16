import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive utility class to help with adaptive layouts
class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  /// Get screen width
  double get width => MediaQuery.of(context).size.width;
  
  /// Get screen height
  double get height => MediaQuery.of(context).size.height;
  
  /// Check if screen is mobile
  bool get isMobile => width < ResponsiveBreakpoints.mobile;
  
  /// Check if screen is tablet
  bool get isTablet => 
      width >= ResponsiveBreakpoints.mobile && 
      width < ResponsiveBreakpoints.desktop;
  
  /// Get value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }
  
  /// Get padding based on screen size
  EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: value(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    ),
    vertical: value(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    ),
  );
  
  /// Get max width for content containers
  double get maxContentWidth => value(
    mobile: double.infinity,
    tablet: 768.0,
    desktop: 1200.0,
  );
  
  /// Get column count for grids
  int get gridColumns => value(
    mobile: 2,
    tablet: 2,
    desktop: 7,
  );
}

extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}


