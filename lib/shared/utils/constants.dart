class AppConstants {
  // App Information
  static const String appName = 'Allma';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI Companion Platform';

  // API Configuration
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1';
  static const String geminiModel = 'gemini-2.5-flash';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // Database
  static const String databaseName = 'allma.db';
  static const int databaseVersion = 1;

  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String companionsKey = 'companions';
  static const String conversationsKey = 'conversations';
  static const String memoryItemsKey = 'memory_items';

  // Security
  static const String encryptionKeyAlias = 'allma_master_key';
  static const Duration sessionTimeout = Duration(minutes: 15);

  // Memory Management
  static const int maxMemoryItems = 1000;
  static const int defaultContextWindowSize = 8000;
  static const Duration memoryRetentionPeriod = Duration(days: 365);

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Chat Configuration
  static const int maxMessageLength = 2000;
  static const Duration typingIndicatorDelay = Duration(milliseconds: 500);
  static const Duration messageDelay = Duration(milliseconds: 100);

  // Safety Thresholds
  static const double defaultSafetyThreshold = 0.7;
  static const int maxConsecutiveWarnings = 3;

  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  // File Paths
  static const String assetsPath = 'assets/';
  static const String imagesPath = '${assetsPath}images/';
  static const String fontsPath = '${assetsPath}fonts/';

  // Error Messages
  static const String networkErrorMessage = 'Network connection failed. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error occurred. Please try again later.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  static const String unknownErrorMessage = 'An unexpected error occurred. Please try again.';

  // Success Messages
  static const String companionCreatedMessage = 'Companion created successfully!';
  static const String settingsSavedMessage = 'Settings saved successfully!';
  static const String dataExportedMessage = 'Data exported successfully!';

  // Feature Flags (from environment)
  static bool get isDebugMode => const bool.fromEnvironment('DEBUG_MODE', defaultValue: false);
  static bool get analyticsEnabled => const bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
  static bool get crashReportingEnabled => const bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);
}