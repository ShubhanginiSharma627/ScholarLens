import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/audio_service.dart';
import 'package:scholar_lens/models/app_state.dart';
import 'dart:async';
class MockAudioService implements AudioService {
  final StreamController<AudioState> _audioStateController = StreamController<AudioState>.broadcast();
  AudioState _currentState = AudioState.idle;
  @override
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _updateState(AudioState.playing);
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
      const testCases = [
        ['# Header 1', 'Header 1'],
        ['## Header 2', 'Header 2'],
        ['### Header 3', 'Header 3'],
        ['**bold text**', 'bold text'],
        ['*italic text*', 'italic text'],
        ['`code snippet`', 'code snippet'],
        ['[link text](http://example.com)', 'link text'],
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
String _cleanMarkdownSymbols(String text) {
  String cleaned = text;
  cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
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
  cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) => match.group(1) ?? '');
  cleaned = cleaned.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
  cleaned = cleaned.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
  cleaned = cleaned.replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '');
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned;
}