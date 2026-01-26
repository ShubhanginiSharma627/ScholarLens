import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Service for handling graceful degradation when features are unavailable
class GracefulDegradationService {
  static GracefulDegradationService? _instance;
  static GracefulDegradationService get instance => _instance ??= GracefulDegradationService._();

  GracefulDegradationService._();

  // Feature availability cache
  final Map<String, bool> _featureAvailability = {};
  final Map<String, DateTime> _lastChecked = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);

  /// Checks if camera functionality is available
  Future<bool> isCameraAvailable() async {
    return await _checkFeatureAvailability('camera', () async {
      try {
        // Check if camera permission can be requested
        const platform = MethodChannel('flutter/camera');
        final cameras = await platform.invokeMethod('availableCameras');
        return cameras != null && (cameras as List).isNotEmpty;
      } catch (e) {
        debugPrint('Camera availability check failed: $e');
        return false;
      }
    });
  }

  /// Checks if audio/TTS functionality is available
  Future<bool> isAudioAvailable() async {
    return await _checkFeatureAvailability('audio', () async {
      try {
        // Check if TTS is available on the platform
        if (Platform.isIOS || Platform.isAndroid) {
          return true; // TTS is generally available on mobile platforms
        }
        return false;
      } catch (e) {
        debugPrint('Audio availability check failed: $e');
        return false;
      }
    });
  }

  /// Checks if voice input/speech recognition is available
  Future<bool> isVoiceInputAvailable() async {
    return await _checkFeatureAvailability('voice', () async {
      try {
        // Check if speech recognition is available
        const platform = MethodChannel('speech_to_text');
        final available = await platform.invokeMethod('has_permission');
        return available == true;
      } catch (e) {
        debugPrint('Voice input availability check failed: $e');
        return false;
      }
    });
  }

  /// Checks if network connectivity is available
  Future<bool> isNetworkAvailable() async {
    return await _checkFeatureAvailability('network', () async {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        debugPrint('Network availability check failed: $e');
        return false;
      }
    });
  }

  /// Checks if storage is available and has sufficient space
  Future<bool> isStorageAvailable({int requiredSpaceMB = 10}) async {
    return await _checkFeatureAvailability('storage_$requiredSpaceMB', () async {
      try {
        // This is a simplified check - in a real app you'd use a plugin
        // to check actual storage space
        return true; // Assume storage is available for now
      } catch (e) {
        debugPrint('Storage availability check failed: $e');
        return false;
      }
    });
  }

  /// Gets feature availability with fallback options
  Future<FeatureAvailability> getFeatureAvailability() async {
    final results = await Future.wait([
      isCameraAvailable(),
      isAudioAvailable(),
      isVoiceInputAvailable(),
      isNetworkAvailable(),
      isStorageAvailable(),
    ]);

    return FeatureAvailability(
      camera: results[0],
      audio: results[1],
      voiceInput: results[2],
      network: results[3],
      storage: results[4],
    );
  }

  /// Gets degradation strategy for a specific feature
  DegradationStrategy getDegradationStrategy(String feature, bool isAvailable) {
    if (isAvailable) {
      return DegradationStrategy(
        isAvailable: true,
        fallbackOption: null,
        userMessage: null,
        actionRequired: false,
      );
    }

    switch (feature.toLowerCase()) {
      case 'camera':
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'gallery_picker',
          userMessage: 'Camera not available. You can select images from your gallery instead.',
          actionRequired: true,
          fallbackIcon: 'photo_library',
          fallbackLabel: 'Choose from Gallery',
        );

      case 'audio':
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'text_only',
          userMessage: 'Audio playback not available. Content will be displayed as text only.',
          actionRequired: false,
          fallbackIcon: 'text_fields',
          fallbackLabel: 'Text Mode',
        );

      case 'voice':
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'text_input',
          userMessage: 'Voice input not available. You can type your questions instead.',
          actionRequired: false,
          fallbackIcon: 'keyboard',
          fallbackLabel: 'Type Instead',
        );

      case 'network':
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'offline_mode',
          userMessage: 'No internet connection. Using offline mode with limited functionality.',
          actionRequired: false,
          fallbackIcon: 'offline_bolt',
          fallbackLabel: 'Offline Mode',
        );

      case 'storage':
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'memory_only',
          userMessage: 'Storage full. Some features may not save data permanently.',
          actionRequired: true,
          fallbackIcon: 'storage',
          fallbackLabel: 'Free Space',
        );

      default:
        return DegradationStrategy(
          isAvailable: false,
          fallbackOption: 'disabled',
          userMessage: 'This feature is currently unavailable.',
          actionRequired: false,
        );
    }
  }

  /// Gets user-friendly message for feature unavailability
  String getUnavailabilityMessage(String feature) {
    final strategy = getDegradationStrategy(feature, false);
    return strategy.userMessage ?? 'Feature unavailable';
  }

  /// Gets fallback options for a feature
  List<FallbackOption> getFallbackOptions(String feature) {
    switch (feature.toLowerCase()) {
      case 'camera':
        return [
          FallbackOption(
            id: 'gallery',
            label: 'Choose from Gallery',
            icon: 'photo_library',
            description: 'Select an existing image from your device',
          ),
          FallbackOption(
            id: 'demo',
            label: 'Try Demo',
            icon: 'play_circle',
            description: 'Use a sample image to explore features',
          ),
        ];

      case 'audio':
        return [
          FallbackOption(
            id: 'text_display',
            label: 'Read Text',
            icon: 'text_fields',
            description: 'View content as formatted text',
          ),
          FallbackOption(
            id: 'visual_cues',
            label: 'Visual Mode',
            icon: 'visibility',
            description: 'Enhanced visual presentation',
          ),
        ];

      case 'voice':
        return [
          FallbackOption(
            id: 'text_input',
            label: 'Type Message',
            icon: 'keyboard',
            description: 'Enter your question using the keyboard',
          ),
          FallbackOption(
            id: 'quick_questions',
            label: 'Quick Questions',
            icon: 'quiz',
            description: 'Choose from common questions',
          ),
        ];

      case 'network':
        return [
          FallbackOption(
            id: 'offline_content',
            label: 'Offline Content',
            icon: 'offline_bolt',
            description: 'Access downloaded content and demos',
          ),
          FallbackOption(
            id: 'cached_data',
            label: 'Recent Content',
            icon: 'history',
            description: 'View previously loaded content',
          ),
        ];

      default:
        return [];
    }
  }

  /// Checks if a feature should be hidden completely
  bool shouldHideFeature(String feature, bool isAvailable) {
    if (isAvailable) return false;

    // Some features should be hidden if not available
    switch (feature.toLowerCase()) {
      case 'voice':
        return true; // Hide voice button if not available
      case 'camera':
        return false; // Show camera with fallback options
      case 'audio':
        return false; // Show audio controls but disable them
      default:
        return false;
    }
  }

  /// Invalidates feature availability cache
  void invalidateCache([String? feature]) {
    if (feature != null) {
      _featureAvailability.remove(feature);
      _lastChecked.remove(feature);
    } else {
      _featureAvailability.clear();
      _lastChecked.clear();
    }
  }

  /// Generic method to check feature availability with caching
  Future<bool> _checkFeatureAvailability(
    String feature,
    Future<bool> Function() checker,
  ) async {
    // Check cache first
    final lastCheck = _lastChecked[feature];
    if (lastCheck != null && 
        DateTime.now().difference(lastCheck) < _cacheExpiry &&
        _featureAvailability.containsKey(feature)) {
      return _featureAvailability[feature]!;
    }

    // Perform actual check
    try {
      final isAvailable = await checker();
      _featureAvailability[feature] = isAvailable;
      _lastChecked[feature] = DateTime.now();
      return isAvailable;
    } catch (e) {
      debugPrint('Feature availability check failed for $feature: $e');
      _featureAvailability[feature] = false;
      _lastChecked[feature] = DateTime.now();
      return false;
    }
  }
}

/// Overall feature availability status
class FeatureAvailability {
  final bool camera;
  final bool audio;
  final bool voiceInput;
  final bool network;
  final bool storage;

  const FeatureAvailability({
    required this.camera,
    required this.audio,
    required this.voiceInput,
    required this.network,
    required this.storage,
  });

  /// Gets the overall app functionality level
  AppFunctionalityLevel get functionalityLevel {
    final availableFeatures = [camera, audio, voiceInput, network, storage]
        .where((feature) => feature)
        .length;

    if (availableFeatures >= 4) {
      return AppFunctionalityLevel.full;
    } else if (availableFeatures >= 2) {
      return AppFunctionalityLevel.limited;
    } else {
      return AppFunctionalityLevel.minimal;
    }
  }

  /// Gets a user-friendly description of current functionality
  String get functionalityDescription {
    switch (functionalityLevel) {
      case AppFunctionalityLevel.full:
        return 'All features are available';
      case AppFunctionalityLevel.limited:
        return 'Some features are unavailable but core functionality works';
      case AppFunctionalityLevel.minimal:
        return 'Limited functionality - some features may not work';
    }
  }

  @override
  String toString() {
    return 'FeatureAvailability(camera: $camera, audio: $audio, voice: $voiceInput, network: $network, storage: $storage)';
  }
}

/// Strategy for handling feature degradation
class DegradationStrategy {
  final bool isAvailable;
  final String? fallbackOption;
  final String? userMessage;
  final bool actionRequired;
  final String? fallbackIcon;
  final String? fallbackLabel;

  const DegradationStrategy({
    required this.isAvailable,
    this.fallbackOption,
    this.userMessage,
    required this.actionRequired,
    this.fallbackIcon,
    this.fallbackLabel,
  });
}

/// Fallback option for unavailable features
class FallbackOption {
  final String id;
  final String label;
  final String icon;
  final String description;

  const FallbackOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}

/// App functionality levels
enum AppFunctionalityLevel {
  full,    // All features available
  limited, // Some features unavailable
  minimal, // Most features unavailable
}

/// Mixin for widgets that need graceful degradation
mixin GracefulDegradationMixin<T extends StatefulWidget> on State<T> {
  /// Checks feature availability and handles degradation
  Future<bool> checkFeatureOrDegrade(
    String feature,
    VoidCallback onAvailable, {
    VoidCallback? onUnavailable,
    bool showFallbackOptions = true,
  }) async {
    final service = GracefulDegradationService.instance;
    bool isAvailable = false;

    switch (feature.toLowerCase()) {
      case 'camera':
        isAvailable = await service.isCameraAvailable();
        break;
      case 'audio':
        isAvailable = await service.isAudioAvailable();
        break;
      case 'voice':
        isAvailable = await service.isVoiceInputAvailable();
        break;
      case 'network':
        isAvailable = await service.isNetworkAvailable();
        break;
      case 'storage':
        isAvailable = await service.isStorageAvailable();
        break;
    }

    if (isAvailable) {
      onAvailable();
      return true;
    } else {
      if (onUnavailable != null) {
        onUnavailable();
      } else if (showFallbackOptions) {
        _showFallbackOptions(feature);
      }
      return false;
    }
  }

  /// Shows fallback options for unavailable feature
  void _showFallbackOptions(String feature) {
    final service = GracefulDegradationService.instance;
    final options = service.getFallbackOptions(feature);
    final message = service.getUnavailabilityMessage(feature);

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Alternative Options:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...options.map((option) => ListTile(
              leading: Icon(_getIconData(option.icon)),
              title: Text(option.label),
              subtitle: Text(option.description),
              onTap: () {
                Navigator.of(context).pop();
                _handleFallbackOption(feature, option.id);
              },
            )),
          ],
        ),
      ),
    );
  }

  /// Handles selection of fallback option
  void _handleFallbackOption(String feature, String optionId) {
    // Override this method in implementing widgets
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected fallback: $optionId for $feature'),
      ),
    );
  }

  /// Converts icon string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'photo_library':
        return Icons.photo_library;
      case 'play_circle':
        return Icons.play_circle;
      case 'text_fields':
        return Icons.text_fields;
      case 'visibility':
        return Icons.visibility;
      case 'keyboard':
        return Icons.keyboard;
      case 'quiz':
        return Icons.quiz;
      case 'offline_bolt':
        return Icons.offline_bolt;
      case 'history':
        return Icons.history;
      case 'storage':
        return Icons.storage;
      default:
        return Icons.help;
    }
  }
}