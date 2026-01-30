import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import 'audio_service.dart';
import 'voice_input_service.dart';
import 'tutor_service.dart';
class AudioController extends ChangeNotifier {
  final AudioService _audioService;
  final VoiceInputService _voiceInputService;
  final TutorService _tutorService;
  late StreamSubscription<AudioState> _audioStateSubscription;
  late StreamSubscription<VoiceInputState> _voiceStateSubscription;
  AudioState _audioState = AudioState.idle;
  VoiceInputState _voiceState = VoiceInputState.idle;
  String _currentAudioText = '';
  bool _isProcessingVoiceInput = false;
  AudioController({
    required AudioService audioService,
    required VoiceInputService voiceInputService,
    required TutorService tutorService,
  }) : _audioService = audioService,
       _voiceInputService = voiceInputService,
       _tutorService = tutorService {
    _initializeStreams();
  }
  AudioState get audioState => _audioState;
  VoiceInputState get voiceState => _voiceState;
  String get currentAudioText => _currentAudioText;
  bool get isProcessingVoiceInput => _isProcessingVoiceInput;
  bool get isAudioPlaying => _audioState == AudioState.playing;
  bool get isListening => _voiceState == VoiceInputState.listening;
  void _initializeStreams() {
    _audioStateSubscription = _audioService.audioStateStream.listen((state) {
      _audioState = state;
      notifyListeners();
    });
    _voiceStateSubscription = _voiceInputService.voiceStateStream.listen((state) {
      _voiceState = state;
      notifyListeners();
    });
  }
  Future<void> speak(String text) async {
    try {
      _currentAudioText = text;
      await _audioService.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      rethrow;
    }
  }
  Future<void> pauseAudio() async {
    try {
      await _audioService.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      rethrow;
    }
  }
  Future<void> stopAudio() async {
    try {
      await _audioService.stop();
      _currentAudioText = '';
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      rethrow;
    }
  }
  Future<String> startVoiceInput() async {
    try {
      _isProcessingVoiceInput = true;
      notifyListeners();
      final recognizedText = await _voiceInputService.startListening();
      _isProcessingVoiceInput = false;
      notifyListeners();
      return recognizedText;
    } catch (e) {
      _isProcessingVoiceInput = false;
      notifyListeners();
      debugPrint('Error with voice input: $e');
      rethrow;
    }
  }
  void stopVoiceInput() {
    try {
      _voiceInputService.stopListening();
      _isProcessingVoiceInput = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping voice input: $e');
    }
  }
  Future<String> processVoiceQuestion(String context) async {
    try {
      if (isAudioPlaying) {
        await stopAudio();
      }
      final question = await startVoiceInput();
      if (question.isEmpty) {
        throw AudioControllerException('No voice input received');
      }
      final response = await _tutorService.askFollowUpQuestion(question, context);
      return response;
    } catch (e) {
      debugPrint('Error processing voice question: $e');
      rethrow;
    }
  }
  Future<bool> isVoiceInputAvailable() async {
    try {
      return await _voiceInputService.isAvailable;
    } catch (e) {
      debugPrint('Error checking voice input availability: $e');
      return false;
    }
  }
  void handleNavigation() {
    if (isAudioPlaying) {
      stopAudio();
    }
    if (isListening) {
      stopVoiceInput();
    }
  }
  Future<void> speakLessonContent(String audioTranscript) async {
    try {
      await speak(audioTranscript);
    } catch (e) {
      throw AudioControllerException('Failed to speak lesson content: $e');
    }
  }
  Future<String> handleChatVoiceInput() async {
    try {
      return await startVoiceInput();
    } catch (e) {
      throw AudioControllerException('Failed to process chat voice input: $e');
    }
  }
  @override
  void dispose() {
    _audioStateSubscription.cancel();
    _voiceStateSubscription.cancel();
    _audioService.dispose();
    _voiceInputService.dispose();
    super.dispose();
  }
}
class AudioControllerException implements Exception {
  final String message;
  final dynamic originalError;
  const AudioControllerException(this.message, [this.originalError]);
  @override
  String toString() => 'AudioControllerException: $message';
}