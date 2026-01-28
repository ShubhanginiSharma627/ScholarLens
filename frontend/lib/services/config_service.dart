import 'package:flutter/foundation.dart';

class ConfigService {
  // Singleton pattern
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? 'http://localhost:3000/api' : 'https://your-production-api.com/api',
  );
  
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );
  
  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMeasurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  
  // Google Services
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String googleAnalyticsId = String.fromEnvironment('GOOGLE_ANALYTICS_ID');
  
  // App Configuration
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'Scholar Lens');
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const String appEnvironment = String.fromEnvironment('APP_ENVIRONMENT', defaultValue: 'development');
  
  // Feature Flags
  static const bool enableOfflineMode = bool.fromEnvironment('ENABLE_OFFLINE_MODE', defaultValue: true);
  static const bool enableVoiceInput = bool.fromEnvironment('ENABLE_VOICE_INPUT', defaultValue: true);
  static const bool enableCameraFeatures = bool.fromEnvironment('ENABLE_CAMERA_FEATURES', defaultValue: true);
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  static const bool enablePushNotifications = bool.fromEnvironment('ENABLE_PUSH_NOTIFICATIONS', defaultValue: true);
  
  // Performance
  static const bool enablePerformanceMonitoring = bool.fromEnvironment('ENABLE_PERFORMANCE_MONITORING', defaultValue: true);
  static const int cacheDuration = int.fromEnvironment('CACHE_DURATION', defaultValue: 300000);
  static const int imageCacheSize = int.fromEnvironment('IMAGE_CACHE_SIZE', defaultValue: 100);
  
  // Security
  static const bool enableBiometricAuth = bool.fromEnvironment('ENABLE_BIOMETRIC_AUTH', defaultValue: true);
  static const int sessionTimeout = int.fromEnvironment('SESSION_TIMEOUT', defaultValue: 1800000);
  static const int autoLogoutWarning = int.fromEnvironment('AUTO_LOGOUT_WARNING', defaultValue: 300000);
  
  // AI Features
  static const bool enableAiTutor = bool.fromEnvironment('ENABLE_AI_TUTOR', defaultValue: true);
  static const bool enableSmartRecommendations = bool.fromEnvironment('ENABLE_SMART_RECOMMENDATIONS', defaultValue: true);
  static const int maxChatHistory = int.fromEnvironment('MAX_CHAT_HISTORY', defaultValue: 50);
  static const int aiResponseTimeout = int.fromEnvironment('AI_RESPONSE_TIMEOUT', defaultValue: 15000);
  
  // Debugging
  static const bool enableDebugMode = bool.fromEnvironment('ENABLE_DEBUG_MODE', defaultValue: kDebugMode);
  static const String logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
  static const bool enableCrashReporting = bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: true);
  
  // Social Features
  static const bool enableSocialSharing = bool.fromEnvironment('ENABLE_SOCIAL_SHARING', defaultValue: true);
  static const bool enableStudyGroups = bool.fromEnvironment('ENABLE_STUDY_GROUPS', defaultValue: false);
  
  // Accessibility
  static const bool enableHighContrast = bool.fromEnvironment('ENABLE_HIGH_CONTRAST', defaultValue: true);
  static const bool enableLargeText = bool.fromEnvironment('ENABLE_LARGE_TEXT', defaultValue: true);
  static const bool enableVoiceOver = bool.fromEnvironment('ENABLE_VOICE_OVER', defaultValue: true);
  
  // Getters for computed values
  bool get isProduction => appEnvironment == 'production';
  bool get isDevelopment => appEnvironment == 'development';
  bool get isStaging => appEnvironment == 'staging';
  
  Duration get apiTimeoutDuration => Duration(milliseconds: apiTimeout);
  Duration get cacheDurationDuration => Duration(milliseconds: cacheDuration);
  Duration get sessionTimeoutDuration => Duration(milliseconds: sessionTimeout);
  Duration get autoLogoutWarningDuration => Duration(milliseconds: autoLogoutWarning);
  Duration get aiResponseTimeoutDuration => Duration(milliseconds: aiResponseTimeout);
  
  // Validation methods
  bool get isFirebaseConfigured => 
      firebaseApiKey.isNotEmpty && 
      firebaseProjectId.isNotEmpty && 
      firebaseAppId.isNotEmpty;
  
  bool get isGoogleServicesConfigured => googleMapsApiKey.isNotEmpty;
  
  // Configuration summary for debugging
  Map<String, dynamic> get configSummary => {
    'app': {
      'name': appName,
      'version': appVersion,
      'environment': appEnvironment,
    },
    'api': {
      'baseUrl': apiBaseUrl,
      'timeout': apiTimeout,
    },
    'features': {
      'offlineMode': enableOfflineMode,
      'voiceInput': enableVoiceInput,
      'cameraFeatures': enableCameraFeatures,
      'analytics': enableAnalytics,
      'pushNotifications': enablePushNotifications,
      'aiTutor': enableAiTutor,
      'smartRecommendations': enableSmartRecommendations,
      'socialSharing': enableSocialSharing,
      'studyGroups': enableStudyGroups,
    },
    'security': {
      'biometricAuth': enableBiometricAuth,
      'sessionTimeout': sessionTimeout,
    },
    'performance': {
      'performanceMonitoring': enablePerformanceMonitoring,
      'cacheDuration': cacheDuration,
      'imageCacheSize': imageCacheSize,
    },
    'accessibility': {
      'highContrast': enableHighContrast,
      'largeText': enableLargeText,
      'voiceOver': enableVoiceOver,
    },
    'debugging': {
      'debugMode': enableDebugMode,
      'logLevel': logLevel,
      'crashReporting': enableCrashReporting,
    },
    'integrations': {
      'firebaseConfigured': isFirebaseConfigured,
      'googleServicesConfigured': isGoogleServicesConfigured,
    },
  };
  
  // Print configuration for debugging
  void printConfig() {
    if (enableDebugMode) {
      debugPrint('=== Scholar Lens Configuration ===');
      debugPrint('Environment: $appEnvironment');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint('Firebase Configured: $isFirebaseConfigured');
      debugPrint('Google Services Configured: $isGoogleServicesConfigured');
      debugPrint('Feature Flags:');
      debugPrint('  - Offline Mode: $enableOfflineMode');
      debugPrint('  - Voice Input: $enableVoiceInput');
      debugPrint('  - Camera Features: $enableCameraFeatures');
      debugPrint('  - AI Tutor: $enableAiTutor');
      debugPrint('  - Analytics: $enableAnalytics');
      debugPrint('==================================');
    }
  }
}