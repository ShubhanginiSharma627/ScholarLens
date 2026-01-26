import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/voice_input_service.dart';
import 'package:scholar_lens/models/app_state.dart';
import 'dart:async';

/// Mock implementation of VoiceInputService for testing
class MockVoiceInputService implements VoiceInputService {
  final StreamController<VoiceInputState> _voiceStateController = StreamController<VoiceInputState>.broadcast();
  VoiceInputState _currentState = VoiceInputState.idle;
  bool _isAvailableValue = true;
  
  @override
  Future<String> startListening() async {
    if (_currentState == VoiceInputState.listening) {
      throw VoiceInputException('Already listening');
    }
    
    _updateState(VoiceInputState.listening);
    
    // Simulate listening process
    await Future.delayed(const Duration(milliseconds: 100));
    _updateState(VoiceInputState.processing);
    
    await Future.delayed(const Duration(milliseconds: 50));
    _updateState(VoiceInputState.idle);
    
    return 'Hello world'; // Mock recognized text
  }
  
  @override
  void stopListening() {
    if (_currentState == VoiceInputState.listening) {
      _updateState(VoiceInputState.processing);
    }
  }
  
  @override
  Stream<VoiceInputState> get voiceStateStream => _voiceStateController.stream;
  
  @override
  VoiceInputState get currentState => _currentState;
  
  @override
  Future<bool> get isAvailable async => _isAvailableValue;
  
  void _updateState(VoiceInputState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _voiceStateController.add(newState);
    }
  }
  
  /// Test helper to simulate unavailable service
  void setAvailable(bool available) {
    _isAvailableValue = available;
  }
  
  /// Test helper to simulate error
  void simulateError() {
    _updateState(VoiceInputState.error);
  }
  
  @override
  void dispose() {
    _voiceStateController.close();
  }
}

void main() {
  group('MockVoiceInputService', () {
    late MockVoiceInputService voiceInputService;

    setUp(() {
      voiceInputService = MockVoiceInputService();
    });

    tearDown(() {
      voiceInputService.dispose();
    });

    test('should initialize with idle state', () {
      expect(voiceInputService.currentState, VoiceInputState.idle);
    });

    test('should be available by default', () async {
      expect(await voiceInputService.isAvailable, true);
    });

    test('should change states during listening process', () async {
      final stateChanges = <VoiceInputState>[];
      final subscription = voiceInputService.voiceStateStream.listen(stateChanges.add);
      
      final result = await voiceInputService.startListening();
      
      expect(result, 'Hello world');
      expect(stateChanges, contains(VoiceInputState.listening));
      expect(stateChanges, contains(VoiceInputState.processing));
      expect(voiceInputService.currentState, VoiceInputState.idle);
      
      await subscription.cancel();
    });

    test('should throw exception when already listening', () async {
      // Start listening
      final future = voiceInputService.startListening();
      
      // Try to start listening again while already listening
      expect(
        () => voiceInputService.startListening(),
        throwsA(isA<VoiceInputException>()),
      );
      
      // Wait for the first listening to complete
      await future;
    });

    test('should handle stop listening', () {
      voiceInputService._updateState(VoiceInputState.listening);
      voiceInputService.stopListening();
      expect(voiceInputService.currentState, VoiceInputState.processing);
    });

    test('should provide voice state stream', () {
      expect(voiceInputService.voiceStateStream, isA<Stream<VoiceInputState>>());
    });

    test('should handle availability changes', () async {
      voiceInputService.setAvailable(false);
      expect(await voiceInputService.isAvailable, false);
      
      voiceInputService.setAvailable(true);
      expect(await voiceInputService.isAvailable, true);
    });

    test('should handle error state', () async {
      final stateChanges = <VoiceInputState>[];
      final subscription = voiceInputService.voiceStateStream.listen(stateChanges.add);
      
      voiceInputService.simulateError();
      
      // Wait a bit for the stream to propagate
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(voiceInputService.currentState, VoiceInputState.error);
      expect(stateChanges, contains(VoiceInputState.error));
      
      await subscription.cancel();
    });
  });

  group('VoiceInputException', () {
    test('should create exception with message', () {
      const exception = VoiceInputException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'VoiceInputException: Test error');
    });

    test('should create exception with message and original error', () {
      final originalError = Exception('Original');
      final exception = VoiceInputException('Test error', originalError);
      expect(exception.message, 'Test error');
      expect(exception.originalError, originalError);
    });
  });

  group('VoiceInputResult', () {
    test('should create result with all properties', () {
      const result = VoiceInputResult(
        text: 'Hello world',
        confidence: 0.95,
        isFinal: true,
        duration: Duration(seconds: 2),
      );
      
      expect(result.text, 'Hello world');
      expect(result.confidence, 0.95);
      expect(result.isFinal, true);
      expect(result.duration, const Duration(seconds: 2));
    });

    test('should have proper string representation', () {
      const result = VoiceInputResult(
        text: 'Test',
        confidence: 0.8,
        isFinal: false,
        duration: Duration(seconds: 1),
      );
      
      expect(result.toString(), 'VoiceInputResult(text: "Test", confidence: 0.8, final: false)');
    });
  });
}