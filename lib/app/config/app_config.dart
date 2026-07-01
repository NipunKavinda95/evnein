class AppConfig {
  static const String appName = 'EVNEIN';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Juice & Cake Shop';

  // Loyalty thresholds
  static const int pointsPerHundred = 1;
  static const int freeJuiceThreshold = 500;
  static const int freeCakeThreshold = 1000;

  // Stock alert threshold
  static const int lowStockThreshold = 5;

  // Feedback alert threshold
  static const int negativeFeedbackThreshold = 3;
}
