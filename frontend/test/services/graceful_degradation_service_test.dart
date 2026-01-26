import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/graceful_degradation_service.dart';

void main() {
  group('GracefulDegradationService', () {
    late GracefulDegradationService service;

    setUp(() {
      service = GracefulDegradationService.instance;
    });

    test('should provide degradation strategy for unavailable camera', () {
      final strategy = service.getDegradationStrategy('camera', false);

      expect(strategy.isAvailable, false);
      expect(strategy.fallbackOption, 'gallery_picker');
      expect(strategy.userMessage, contains('Camera not available'));
      expect(strategy.actionRequired, true);
    });

    test('should provide degradation strategy for unavailable audio', () {
      final strategy = service.getDegradationStrategy('audio', false);

      expect(strategy.isAvailable, false);
      expect(strategy.fallbackOption, 'text_only');
      expect(strategy.userMessage, contains('Audio playback not available'));
      expect(strategy.actionRequired, false);
    });

    test('should provide degradation strategy for unavailable voice', () {
      final strategy = service.getDegradationStrategy('voice', false);

      expect(strategy.isAvailable, false);
      expect(strategy.fallbackOption, 'text_input');
      expect(strategy.userMessage, contains('Voice input not available'));
      expect(strategy.actionRequired, false);
    });

    test('should provide degradation strategy for unavailable network', () {
      final strategy = service.getDegradationStrategy('network', false);

      expect(strategy.isAvailable, false);
      expect(strategy.fallbackOption, 'offline_mode');
      expect(strategy.userMessage, contains('No internet connection'));
      expect(strategy.actionRequired, false);
    });

    test('should provide fallback options for camera', () {
      final options = service.getFallbackOptions('camera');

      expect(options.length, greaterThan(0));
      expect(options.any((o) => o.id == 'gallery'), true);
      expect(options.any((o) => o.id == 'demo'), true);
    });

    test('should provide fallback options for audio', () {
      final options = service.getFallbackOptions('audio');

      expect(options.length, greaterThan(0));
      expect(options.any((o) => o.id == 'text_display'), true);
    });

    test('should provide fallback options for voice', () {
      final options = service.getFallbackOptions('voice');

      expect(options.length, greaterThan(0));
      expect(options.any((o) => o.id == 'text_input'), true);
    });

    test('should provide fallback options for network', () {
      final options = service.getFallbackOptions('network');

      expect(options.length, greaterThan(0));
      expect(options.any((o) => o.id == 'offline_content'), true);
    });

    test('should return empty fallback options for unknown feature', () {
      final options = service.getFallbackOptions('unknown');

      expect(options.length, 0);
    });

    test('should determine if feature should be hidden', () {
      expect(service.shouldHideFeature('voice', false), true);
      expect(service.shouldHideFeature('camera', false), false);
      expect(service.shouldHideFeature('audio', false), false);
    });

    test('should get unavailability message', () {
      final message = service.getUnavailabilityMessage('camera');
      expect(message, contains('Camera not available'));
    });

    test('should invalidate cache', () {
      // This is a basic test since we can't easily test the internal cache
      expect(() => service.invalidateCache(), returnsNormally);
      expect(() => service.invalidateCache('camera'), returnsNormally);
    });
  });

  group('FeatureAvailability', () {
    test('should calculate functionality level correctly', () {
      // Full functionality
      final fullAvailability = FeatureAvailability(
        camera: true,
        audio: true,
        voiceInput: true,
        network: true,
        storage: true,
      );
      expect(fullAvailability.functionalityLevel, AppFunctionalityLevel.full);

      // Limited functionality
      final limitedAvailability = FeatureAvailability(
        camera: true,
        audio: true,
        voiceInput: false,
        network: false,
        storage: true,
      );
      expect(limitedAvailability.functionalityLevel, AppFunctionalityLevel.limited);

      // Minimal functionality
      final minimalAvailability = FeatureAvailability(
        camera: false,
        audio: false,
        voiceInput: false,
        network: false,
        storage: true,
      );
      expect(minimalAvailability.functionalityLevel, AppFunctionalityLevel.minimal);
    });

    test('should provide functionality description', () {
      final availability = FeatureAvailability(
        camera: true,
        audio: true,
        voiceInput: true,
        network: true,
        storage: true,
      );

      expect(availability.functionalityDescription, contains('All features are available'));
    });

    test('should provide string representation', () {
      final availability = FeatureAvailability(
        camera: true,
        audio: false,
        voiceInput: true,
        network: false,
        storage: true,
      );

      final str = availability.toString();
      expect(str, contains('camera: true'));
      expect(str, contains('audio: false'));
    });
  });

  group('DegradationStrategy', () {
    test('should create degradation strategy correctly', () {
      const strategy = DegradationStrategy(
        isAvailable: false,
        fallbackOption: 'test_fallback',
        userMessage: 'Test message',
        actionRequired: true,
        fallbackIcon: 'test_icon',
        fallbackLabel: 'Test Label',
      );

      expect(strategy.isAvailable, false);
      expect(strategy.fallbackOption, 'test_fallback');
      expect(strategy.userMessage, 'Test message');
      expect(strategy.actionRequired, true);
      expect(strategy.fallbackIcon, 'test_icon');
      expect(strategy.fallbackLabel, 'Test Label');
    });
  });

  group('FallbackOption', () {
    test('should create fallback option correctly', () {
      const option = FallbackOption(
        id: 'test_id',
        label: 'Test Label',
        icon: 'test_icon',
        description: 'Test description',
      );

      expect(option.id, 'test_id');
      expect(option.label, 'Test Label');
      expect(option.icon, 'test_icon');
      expect(option.description, 'Test description');
    });
  });
}