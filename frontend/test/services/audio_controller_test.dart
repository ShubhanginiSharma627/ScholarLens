import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/audio_controller.dart';
import 'package:scholar_lens/services/audio_service.dart';
import 'package:scholar_lens/services/voice_input_service.dart';
import 'package:scholar_lens/services/tutor_service.dart';
import 'package:scholar_lens/models/app_state.dart';
import 'package:scholar_lens/models/lesson_content.dart';
import 'package:scholar_lens/models/quiz_question.dart';
import 'dart:async';
import 'dart:io';
class MockAudioService implements AudioService {
  final StreamController<AudioState> _audioStateController = StreamController<AudioState>.broadcast();
  AudioState _currentState = AudioState.idle;
  @override
  Future<void> speak(String text) async {
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
class MockVoiceInputService implements VoiceInputService {
  final StreamController<VoiceInputState> _voiceStateController = StreamController<VoiceInputState>.broadcast();
  VoiceInputState _currentState = VoiceInputState.idle;
  @override
  Future<String> startListening() async {
    _updateState(VoiceInputState.listening);
    await Future.delayed(const Duration(milliseconds: 10));
    _updateState(VoiceInputState.processing);
    await Future.delayed(const Duration(milliseconds: 10));
    _updateState(VoiceInputState.idle);
    return 'Hello world';
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
  Future<bool> get isAvailable async => true;
  void _updateState(VoiceInputState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _voiceStateController.add(newState);
    }
  }
  @override
  void dispose() {
    _voiceStateController.close();
  }
}
class MockTutorService implements TutorService {
  @override
  Future<LessonContent> analyzeImage(File image, {String? userPrompt}) async {
    return LessonContent(
      lessonTitle: 'Mock Lesson',
      summaryMarkdown: 'Mock summary content',
      audioTranscript: 'Mock audio transcript',
      quiz: [
        QuizQuestion(
          question: 'Mock question?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Mock explanation',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }
  @override
  Future<String> askFollowUpQuestion(String question, String context) async {
    return 'Mock response to: $question';
  }
  @override
  Future<String> askChapterQuestion({
    required String question,
    required String textbookTitle,
    required int chapterNumber,
    required String sectionTitle,
    required String sectionContent,
    List<String>? highlights,
  }) async {
    return 'Mock chapter response for: $question in $textbookTitle Chapter $chapterNumber';
  }
  @override
  Future<bool> isServiceAvailable() async {
    return true;
  }
}
void main() {
  group('AudioController', () {
    late AudioController audioController;
    late MockAudioService mockAudioService;
    late MockVoiceInputService mockVoiceInputService;
    late MockTutorService mockTutorService;
    setUp(() {
      mockAudioService = MockAudioService();
      mockVoiceInputService = MockVoiceInputService();
      mockTutorService = MockTutorService();
      audioController = AudioController(
        audioService: mockAudioService,
        voiceInputService: mockVoiceInputService,
        tutorService: mockTutorService,
      );
    });
    tearDown(() {
      audioController.dispose();
    });
    test('should initialize with idle states', () {
      expect(audioController.audioState, AudioState.idle);
      expect(audioController.voiceState, VoiceInputState.idle);
      expect(audioController.isAudioPlaying, false);
      expect(audioController.isListening, false);
    });
    test('should speak text and update state', () async {
      await audioController.speak('Hello world');
      expect(audioController.currentAudioText, 'Hello world');
    });
    test('should handle voice input', () async {
      final result = await audioController.startVoiceInput();
      expect(result, 'Hello world');
    });
    test('should process voice question', () async {
      final response = await audioController.processVoiceQuestion('test context');
      expect(response, 'Mock response to: Hello world');
    });
    test('should check voice input availability', () async {
      final isAvailable = await audioController.isVoiceInputAvailable();
      expect(isAvailable, true);
    });
    test('should handle navigation by stopping audio and voice', () {
      audioController.handleNavigation();
    });
    test('should speak lesson content', () async {
      await audioController.speakLessonContent('Lesson audio transcript');
      expect(audioController.currentAudioText, 'Lesson audio transcript');
    });
    test('should handle chat voice input', () async {
      final result = await audioController.handleChatVoiceInput();
      expect(result, 'Hello world');
    });
    test('should pause and stop audio', () async {
      await audioController.pauseAudio();
      await audioController.stopAudio();
      expect(audioController.currentAudioText, '');
    });
    test('should stop voice input', () {
      audioController.stopVoiceInput();
      expect(audioController.isProcessingVoiceInput, false);
    });
  });
  group('AudioControllerException', () {
    test('should create exception with message', () {
      const exception = AudioControllerException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'AudioControllerException: Test error');
    });
    test('should create exception with message and original error', () {
      final originalError = Exception('Original');
      final exception = AudioControllerException('Test error', originalError);
      expect(exception.message, 'Test error');
      expect(exception.originalError, originalError);
    });
  });
}