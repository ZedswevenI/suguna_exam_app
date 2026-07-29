class AppConstants {
  // Displayed as "vX.Y.Z" in the app UI. Bump this alongside the version in
  // pubspec.yaml when releasing.
  static const String appVersion = '1.0.0';

  // API Configuration (for future use)
  static const String baseUrl = 'https://portalapi.z7i.in/api/crm';
  // static const String baseUrl = 'http://143.110.191.245:3012/api/crm';
  // static const String baseUrl = 'http://172.20.10.5:3012/api/crm';
  // static const String baseUrl = 'http://192.168.1.35:3012/api/crm';
  static const Duration timeout = Duration(seconds: 30);

  // Layout Constants
  static const double sidebarWidth = 300.0;
  static const double headerHeight = 64.0;

  static const double circleSize = 24.0;

  static const double circleSpacing = 8.0;

  // Text Sizes
  static const double sectionTitleSize = 18.0;
  static const double normalTextSize = 14.0;
  static const double smallLabelSize = 12.0;

  // Padding & Spacing
  static const double contentPadding = 16.0;
  static const double tightPadding = 8.0;

  // Tablet Landscape Breakpoint
  static const double tabletBreakpoint = 768.0;
}
