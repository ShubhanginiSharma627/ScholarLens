import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/app_state.dart';
abstract class VoiceInputService {
  Future<String> startListening();
  void stopListening();
  Stream<VoiceInputState> get voiceStateStream;
  VoiceInputState get currentState;
  Future<bool> get isAvailable;
  void dispose();
}
class SpeechToTextVoiceInputService implements VoiceInputService {
  final SpeechToText _speechToText = SpeechToText();
  final StreamController<VoiceInputState> _voiceStateController = StreamController<VoiceInputState>.broadcast();
  final Completer<String> _listeningCompleter = Completer<String>();
  VoiceInputState _currentState = VoiceInputState.idle;
  String _recognizedText = '';
  bool _isInitialized = false;
  SpeechToTextVoiceInputService() {
    _initializeSpeechToText();
  }
  Future<void> _initializeSpeechToText() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    } catch (e) {
      _updateState(VoiceInputState.error);
      _isInitialized = false;
    }
  }
  @override
  Future<String> startListening() async {
    if (!_isInitialized) {
      await _initializeSpeechToText();
    }
    if (!_isInitialized) {
      throw VoiceInputException('Speech recognition not available');
    }
    if (_currentState == VoiceInputState.listening) {
      throw VoiceInputException('Already listening');
    }
    _recognizedText = '';
    _updateState(VoiceInputState.listening);
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(partialResults: true),
        localeId: 'en_US',
        onSoundLevelChange: _onSoundLevelChange,
      );
      return await _listeningCompleter.future;
    } catch (e) {
      _updateState(VoiceInputState.error);
      throw VoiceInputException('Failed to start listening: $e');
    }
  }
  @override
  void stopListening() {
    if (_currentState == VoiceInputState.listening) {
      _speechToText.stop();
      _updateState(VoiceInputState.processing);
      if (!_listeningCompleter.isCompleted) {
        _listeningCompleter.complete(_recognizedText);
      }
    }
  }
  @override
  Stream<VoiceInputState> get voiceStateStream => _voiceStateController.stream;
  @override
  VoiceInputState get currentState => _currentState;
  @override
  Future<bool> get isAvailable async {
    if (!_isInitialized) {
      await _initializeSpeechToText();
    }
    return _isInitialized;
  }
  void _updateState(VoiceInputState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _voiceStateController.add(newState);
    }
  }
  void _onSpeechStatus(String status) {
    switch (status) {
      case 'listening':
        _updateState(VoiceInputState.listening);
        break;
      case 'notListening':
        if (_currentState == VoiceInputState.listening) {
          _updateState(VoiceInputState.processing);
        }
        break;
      case 'done':
        _updateState(VoiceInputState.idle);
        if (!_listeningCompleter.isCompleted) {
          _listeningCompleter.complete(_recognizedText);
        }
        break;
    }
  }
  void _onSpeechError(dynamic error) {
    _updateState(VoiceInputState.error);
    if (!_listeningCompleter.isCompleted) {
      _listeningCompleter.completeError(VoiceInputException('Speech recognition error: $error'));
    }
  }
  void _onSpeechResult(dynamic result) {
    if (result != null && result.recognizedWords != null) {
      _recognizedText = result.recognizedWords as String;
      if (result.finalResult == true) {
        _updateState(VoiceInputState.processing);
        if (!_listeningCompleter.isCompleted) {
          _listeningCompleter.complete(_recognizedText);
        }
      }
    }
  }
  void _onSoundLevelChange(double level) {
    if (_currentState != VoiceInputState.listening && _speechToText.isListening) {
      _updateState(VoiceInputState.listening);
    }
  }
  @override
  void dispose() {
    _speechToText.stop();
    _voiceStateController.close();
    if (!_listeningCompleter.isCompleted) {
      _listeningCompleter.complete('');
    }
  }
}
class VoiceInputException implements Exception {
  final String message;
  final dynamic originalError;
  const VoiceInputException(this.message, [this.originalError]);
  @override
  String toString() => 'VoiceInputException: $message';
}
class VoiceInputResult {
  final String text;
  final double confidence;
  final bool isFinal;
  final Duration duration;
  const VoiceInputResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    required this.duration,
  });
  @override
  String toString() => 'VoiceInputResult(text: "$text", confidence: $confidence, final: $isFinal)';
}