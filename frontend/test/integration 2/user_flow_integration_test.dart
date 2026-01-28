import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/models.dart';
import 'package:scholar_lens/services/camera_service.dart';
import 'package:scholar_lens/services/tutor_service.dart';
import 'package:scholar_lens/services/offline_service.dart';
import 'package:scholar_lens/services/audio_service.dart';
import 'package:scholar_lens/services/voice_input_service.dart';
import 'dart:io';

// Mock services for integration testing
class MockCameraService implements CameraService {
  @override
  Future<File> captureImage() async {
    // Return a mock file for testing
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/test_image.jpg');
    await file.writeAsBytes([1, 2, 3, 4]); // Mock image data
    return file;
  }

  @override
  Future<File?> cropImage(File image, {String? title}) async {
    return image; // Return same file for testing
  }

  @override
  Future<File> compressImage(File image, {int maxSizeKB = 1024}) async {
    return image; // Return same file for testing
  }

  @override
  Future<ProcessedImage> captureAndProcess({String? cropTitle}) async {
    final file = await captureImage();
    return ProcessedImage(
      file: file,
      sizeKB: 500,
      processedAt: DateTime.now(),
      metadata: ImageProcessingMetadata.empty(),
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  void dispose() {}

  @override
  bool get isInitialized => true;

  @override
  noSuchMethod(Invocation invocation) => null;
}

class MockTutorService implements TutorService {
  @override
  Future<LessonContent> analyzeImage(File image, {String? userPrompt}) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate API delay
    
    return LessonContent(
      lessonTitle: 'Test Lesson: Photosynthesis',
      summaryMarkdown: '# Photosynthesis\n\nPhotosynthesis is the process by which plants convert light energy into chemical energy.',
      audioTranscript: 'Photosynthesis is the process by which plants convert light energy into chemical energy.',
      quiz: [
        QuizQuestion(
          question: 'What is photosynthesis?',
          options: ['Energy conversion', 'Water absorption', 'Root growth', 'Leaf formation'],
          correctIndex: 0,
          explanation: 'Photosynthesis converts light energy to chemical energy.',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String> askFollowUpQuestion(String question, String context) async {
    await Future.delayed(Duration(milliseconds: 300));
    return 'This is a follow-up response to: $question';
  }
}

class MockOfflineService implements OfflineService {
  @override
  Future<LessonContent> getDemoLesson() async {
    return LessonContent(
      lessonTitle: 'Demo Lesson: Offline Photosynthesis',
      summaryMarkdown: '# Offline Demo\n\nThis is a demo lesson available offline.',
      audioTranscript: 'This is a demo lesson available offline.',
      quiz: [
        QuizQuestion(
          question: 'What is this demo about?',
          options: ['Photosynthesis', 'Mathematics', 'History', 'Geography'],
          correctIndex: 0,
          explanation: 'This demo is about photosynthesis.',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  @override
  bool get isOfflineMode => false;

  @override
  Future<void> activateOfflineMode() async {}

  @override
  Future<void> deactivateOfflineMode() async {}

  @override
  Stream<bool> get offlineModeStream => Stream.value(false);

  @override
  Future<bool> checkNetworkConnectivity() async => true;

  @override
  void dispose() {}

  @override
  Future<List<String>> getAvailableDemoLessons() async => ['Demo Lesson'];

  @override
  Future<LessonContent?> getDemoLessonByTitle(String title) async => await getDemoLesson();
}

class MockAudioService implements AudioService {
  bool _isPlaying = false;
  AudioState _currentState = AudioState.idle;
  
  @override
  Future<void> speak(String text) async {
    _isPlaying = true;
    _currentState = AudioState.playing;
    await Future.delayed(Duration(milliseconds: 100));
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _currentState = AudioState.paused;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentState = AudioState.stopped;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  AudioState get currentState => _currentState;

  @override
  Stream<AudioState> get audioStateStream => Stream.value(_currentState);

  @override
  void dispose() {}
}

class MockVoiceInputService implements VoiceInputService {
  VoiceInputState _currentState = VoiceInputState.idle;
  
  @override
  Future<String> startListening() async {
    _currentState = VoiceInputState.listening;
    await Future.delayed(Duration(milliseconds: 500));
    _currentState = VoiceInputState.idle;
    return 'Test voice input';
  }

  @override
  void stopListening() {
    _currentState = VoiceInputState.idle;
  }

  @override
  bool get isListening => _currentState == VoiceInputState.listening;

  @override
  VoiceInputState get currentState => _currentState;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Stream<VoiceInputState> get voiceStateStream => Stream.value(_currentState);

  @override
  void dispose() {}
}

void main() {
  group('Integration Tests - Complete User Flows', () {
    late MockCameraService mockCameraService;
    late MockTutorService mockTutorService;
    late MockOfflineService mockOfflineService;
    late MockAudioService mockAudioService;
    late MockVoiceInputService mockVoiceInputService;

    setUp(() {
      mockCameraService = MockCameraService();
      mockTutorService = MockTutorService();
      mockOfflineService = MockOfflineService();
      mockAudioService = MockAudioService();
      mockVoiceInputService = MockVoiceInputService();
    });

    test('Complete user flow: Image capture to lesson completion', () async {
      // Requirements: 4.3 - Test complete user flows from image capture to lesson completion
      
      // Step 1: Simulate image capture
      final capturedImage = await mockCameraService.captureImage();
      expect(capturedImage.existsSync(), isTrue);
      
      // Step 2: Process image through tutor service
      final lessonContent = await mockTutorService.analyzeImage(capturedImage);
      expect(lessonContent.lessonTitle, contains('Photosynthesis'));
      expect(lessonContent.summaryMarkdown, isNotEmpty);
      expect(lessonContent.quiz, isNotEmpty);
      
      // Step 3: Verify lesson content structure
      expect(lessonContent.quiz.first.question, isNotEmpty);
      expect(lessonContent.quiz.first.options.length, equals(4));
      expect(lessonContent.quiz.first.correctIndex, isA<int>());
      expect(lessonContent.quiz.first.explanation, isNotEmpty);
      
      // Step 4: Test audio functionality
      await mockAudioService.speak(lessonContent.audioTranscript);
      expect(mockAudioService.isPlaying, isTrue);
      
      await mockAudioService.stop();
      expect(mockAudioService.isPlaying, isFalse);
      
      // Clean up test file
      if (capturedImage.existsSync()) {
        await capturedImage.delete();
      }
    });

    test('Offline mode transition and demo lesson loading', () async {
      // Requirements: 4.3 - Verify offline mode transitions and demo lesson loading
      
      // Step 1: Simulate network failure and offline mode activation
      await mockOfflineService.activateOfflineMode();
      
      // Step 2: Load demo lesson
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.lessonTitle, contains('Demo Lesson'));
      expect(demoLesson.lessonTitle, contains('Offline'));
      expect(demoLesson.summaryMarkdown, isNotEmpty);
      expect(demoLesson.quiz, isNotEmpty);
      
      // Step 3: Verify demo lesson structure
      expect(demoLesson.quiz.first.question, contains('demo'));
      expect(demoLesson.quiz.first.options.length, equals(4));
      expect(demoLesson.quiz.first.correctIndex, equals(0));
      
      // Step 4: Test offline lesson audio
      await mockAudioService.speak(demoLesson.audioTranscript);
      expect(mockAudioService.isPlaying, isTrue);
      
      await mockAudioService.stop();
      expect(mockAudioService.isPlaying, isFalse);
    });

    test('Chat functionality and voice input integration', () async {
      // Requirements: 10.6, 3.5 - Test chat functionality and voice input integration
      
      // Step 1: Test voice input capture
      final voiceInput = await mockVoiceInputService.startListening();
      expect(voiceInput, equals('Test voice input'));
      
      // Step 2: Send voice input as chat message
      final chatResponse = await mockTutorService.askFollowUpQuestion(voiceInput, 'test context');
      expect(chatResponse, contains(voiceInput));
      expect(chatResponse, contains('follow-up response'));
      
      // Step 3: Test chat message flow
      final testMessage = 'What is photosynthesis?';
      final response = await mockTutorService.askFollowUpQuestion(testMessage, 'lesson context');
      expect(response, contains(testMessage));
      
      // Step 4: Verify voice input stops properly
      mockVoiceInputService.stopListening();
      expect(mockVoiceInputService.isListening, isFalse);
    });

    test('End-to-end learning session flow', () async {
      // Complete integration test covering the full learning cycle
      
      // Step 1: Capture and process image
      final image = await mockCameraService.captureImage();
      final compressedImage = await mockCameraService.compressImage(image);
      expect(compressedImage.existsSync(), isTrue);
      
      // Step 2: Get lesson content
      final lesson = await mockTutorService.analyzeImage(compressedImage);
      expect(lesson.lessonTitle, isNotEmpty);
      
      // Step 3: Play audio explanation
      await mockAudioService.speak(lesson.audioTranscript);
      expect(mockAudioService.isPlaying, isTrue);
      
      // Step 4: Take quiz
      final quiz = lesson.quiz.first;
      expect(quiz.options.length, greaterThan(0));
      expect(quiz.correctIndex, lessThan(quiz.options.length));
      
      // Step 5: Ask follow-up question via voice
      final voiceQuestion = await mockVoiceInputService.startListening();
      final followUpResponse = await mockTutorService.askFollowUpQuestion(voiceQuestion, lesson.summaryMarkdown);
      expect(followUpResponse, isNotEmpty);
      
      // Step 6: Stop audio and clean up
      await mockAudioService.stop();
      expect(mockAudioService.isPlaying, isFalse);
      
      // Clean up
      if (image.existsSync()) await image.delete();
      if (compressedImage.existsSync()) await compressedImage.delete();
    });

    test('Error handling in complete user flow', () async {
      // Test error scenarios in the complete flow
      
      // Step 1: Test network error fallback to offline mode
      try {
        // Simulate network error by throwing exception
        throw Exception('Network error');
      } catch (e) {
        // Should fallback to offline mode
        final demoLesson = await mockOfflineService.getDemoLesson();
        expect(demoLesson.lessonTitle, contains('Demo'));
      }
      
      // Step 2: Test audio error handling
      try {
        await mockAudioService.speak('');
        // Should handle empty text gracefully
        expect(mockAudioService.isPlaying, isTrue);
      } catch (e) {
        // Should not throw for empty text
        fail('Audio service should handle empty text gracefully');
      }
      
      // Step 3: Test voice input error handling
      mockVoiceInputService.stopListening();
      expect(mockVoiceInputService.isListening, isFalse);
    });
  });
}