import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/audio_service.dart';
import 'package:scholar_lens/models/app_state.dart';
import 'dart:async';

/// Mock implementation of AudioService for testing
class MockAudioService implements AudioService {
  final StreamController<AudioState> _audioStateController = StreamController<AudioState>.broadcast();
  AudioState _currentState = AudioState.idle;
  
  @override
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _updateState(AudioState.playing);
    // Simulate completion after a short delay
    await Future.delayed(const Duration(milliseconds: 10));
    _updateState(AudioState.idle);
  }
  
  @override
  Future<void> pause() async {
    _updateState(AudioState.paused);
  }
  
  @override
  Future<void> stop() async {
    _updateState(AudioState.stopped);
  }
  
  @override
  bool get isPlaying => _currentState == AudioState.playing;
  
  @override
  Stream<AudioState> get audioStateStream => _audioStateController.stream;
  
  @override
  AudioState get currentState => _currentState;
  
  void _updateState(AudioState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _audioStateController.add(newState);
    }
  }
  
  @override
  void dispose() {
    _audioStateController.close();
  }
}

void main() {
  group('MockAudioService', () {
    late MockAudioService audioService;

    setUp(() {
      audioService = MockAudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('should initialize with idle state', () {
      expect(audioService.currentState, AudioState.idle);
    });

    test('should handle empty text gracefully', () async {
      // Should not throw when speaking empty text
      await expectLater(
        audioService.speak(''),
        completes,
      );
      
      expect(audioService.currentState, AudioState.idle);
    });

    test('should change state when speaking', () async {
      final stateChanges = <AudioState>[];
      final subscription = audioService.audioStateStream.listen(stateChanges.add);
      
      await audioService.speak('Hello world');
      
      // Wait a bit for state changes to propagate
      await Future.delayed(const Duration(milliseconds: 20));
      
      expect(stateChanges, contains(AudioState.playing));
      expect(audioService.currentState, AudioState.idle);
      
      await subscription.cancel();
    });

    test('should provide audio state stream', () {
      expect(audioService.audioStateStream, isA<Stream<AudioState>>());
    });

    test('should handle stop operation', () async {
      await expectLater(
        audioService.stop(),
        completes,
      );
      
      expect(audioService.currentState, AudioState.stopped);
    });

    test('should handle pause operation', () async {
      await expectLater(
        audioService.pause(),
        completes,
      );
      
      expect(audioService.currentState, AudioState.paused);
    });
  });

  group('Markdown Cleaning', () {
    test('should clean various markdown symbols', () {
      // Test markdown cleaning logic directly
      const testCases = [
        // Headers
        ['# Header 1', 'Header 1'],
        ['## Header 2', 'Header 2'],
        ['### Header 3', 'Header 3'],
        
        // Bold and italic - test individually first
        ['**bold text**', 'bold text'],
        ['*italic text*', 'italic text'],
        
        // Inline code
        ['`code snippet`', 'code snippet'],
        
        // Links
        ['[link text](http://example.com)', 'link text'],
        
        // Simple cases first
        ['Hello world', 'Hello world'],
      ];

      for (final testCase in testCases) {
        final input = testCase[0];
        final expected = testCase[1];
        final cleaned = _cleanMarkdownSymbols(input);
        
        expect(cleaned, expected, reason: 'Failed to clean: "$input" -> got "$cleaned" expected "$expected"');
      }
    });
  });

  group('AudioServiceException', () {
    test('should create exception with message', () {
      const exception = AudioServiceException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'AudioServiceException: Test error');
    });

    test('should create exception with message and original error', () {
      final originalError = Exception('Original');
      final exception = AudioServiceException('Test error', originalError);
      expect(exception.message, 'Test error');
      expect(exception.originalError, originalError);
    });
  });
}

/// Helper function to test markdown cleaning (extracted from FlutterAudioService)
String _cleanMarkdownSymbols(String text) {
  String cleaned = text;
  
  // Remove headers
  cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  
  // Remove bold markers - use a different approach
  while (cleaned.contains('**')) {
    final start = cleaned.indexOf('**');
    final end = cleaned.indexOf('**', start + 2);
    if (end != -1) {
      final before = cleaned.substring(0, start);
      final content = cleaned.substring(start + 2, end);
      final after = cleaned.substring(end + 2);
      cleaned = before + content + after;
    } else {
      break;
    }
  }
  
  // Remove italic markers
  while (cleaned.contains('*')) {
    final start = cleaned.indexOf('*');
    final end = cleaned.indexOf('*', start + 1);
    if (end != -1) {
      final before = cleaned.substring(0, start);
      final content = cleaned.substring(start + 1, end);
      final after = cleaned.substring(end + 1);
      cleaned = before + content + after;
    } else {
      break;
    }
  }
  
  // Remove inline code
  while (cleaned.contains('`')) {
    final start = cleaned.indexOf('`');
    final end = cleaned.indexOf('`', start + 1);
    if (end != -1) {
      final before = cleaned.substring(0, start);
      final content = cleaned.substring(start + 1, end);
      final after = cleaned.substring(end + 1);
      cleaned = before + content + after;
    } else {
      break;
    }
  }
  
  // Remove links - simple approach
  cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) => match.group(1) ?? '');
  
  // Remove blockquote markers
  cleaned = cleaned.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
  
  // Remove list markers
  cleaned = cleaned.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
  cleaned = cleaned.replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '');
  
  // Clean up extra whitespace
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  return cleaned;
}