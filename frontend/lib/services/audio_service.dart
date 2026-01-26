import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/app_state.dart';

/// Abstract interface for audio services
abstract class AudioService {
  /// Speaks the given text using TTS
  Future<void> speak(String text);
  
  /// Pauses the current TTS playback
  Future<void> pause();
  
  /// Stops the current TTS playback
  Future<void> stop();
  
  /// Stream of audio state changes
  Stream<AudioState> get audioStateStream;
  
  /// Current audio state
  AudioState get currentState;
  
  /// Whether audio is currently playing
  bool get isPlaying;
  
  /// Disposes of resources
  void dispose();
}

/// Implementation of AudioService using Flutter TTS
class FlutterAudioService implements AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<AudioState> _audioStateController = StreamController<AudioState>.broadcast();
  
  AudioState _currentState = AudioState.idle;
  
  FlutterAudioService() {
    _initializeTts();
  }
  
  /// Initializes the TTS engine with callbacks
  Future<void> _initializeTts() async {
    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      _updateState(AudioState.playing);
    });
    
    _flutterTts.setCompletionHandler(() {
      _updateState(AudioState.idle);
    });
    
    _flutterTts.setCancelHandler(() {
      _updateState(AudioState.stopped);
    });
    
    _flutterTts.setPauseHandler(() {
      _updateState(AudioState.paused);
    });
    
    _flutterTts.setContinueHandler(() {
      _updateState(AudioState.playing);
    });
    
    _flutterTts.setErrorHandler((msg) {
      _updateState(AudioState.idle);
    });
    
    // Configure TTS settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  
  @override
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Clean markdown symbols from text before speaking
    final cleanedText = _cleanMarkdownSymbols(text);
    
    try {
      await _flutterTts.speak(cleanedText);
    } catch (e) {
      _updateState(AudioState.idle);
      rethrow;
    }
  }
  
  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      _updateState(AudioState.idle);
      rethrow;
    }
  }
  
  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      _updateState(AudioState.idle);
      rethrow;
    }
  }
  
  @override
  Stream<AudioState> get audioStateStream => _audioStateController.stream;
  
  @override
  AudioState get currentState => _currentState;
  
  @override
  bool get isPlaying => _currentState == AudioState.playing;
  
  /// Updates the current audio state and notifies listeners
  void _updateState(AudioState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _audioStateController.add(newState);
    }
  }
  
  /// Cleans markdown symbols from text for TTS
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
  
  @override
  void dispose() {
    _flutterTts.stop();
    _audioStateController.close();
  }
}

/// Audio service exception
class AudioServiceException implements Exception {
  final String message;
  final dynamic originalError;
  
  const AudioServiceException(this.message, [this.originalError]);
  
  @override
  String toString() => 'AudioServiceException: $message';
}