import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/app_state.dart';
abstract class AudioService {
  Future<void> speak(String text);
  Future<void> pause();
  Future<void> stop();
  Stream<AudioState> get audioStateStream;
  AudioState get currentState;
  bool get isPlaying;
  void dispose();
}
class FlutterAudioService implements AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<AudioState> _audioStateController = StreamController<AudioState>.broadcast();
  AudioState _currentState = AudioState.idle;
  FlutterAudioService() {
    _initializeTts();
  }
  Future<void> _initializeTts() async {
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
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  @override
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
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
  void _updateState(AudioState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _audioStateController.add(newState);
    }
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
  @override
  void dispose() {
    _flutterTts.stop();
    _audioStateController.close();
  }
}
class AudioServiceException implements Exception {
  final String message;
  final dynamic originalError;
  const AudioServiceException(this.message, [this.originalError]);
  @override
  String toString() => 'AudioServiceException: $message';
}