import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/models.dart';
import 'package:scholar_lens/services/offline_service.dart';
import 'package:scholar_lens/services/network_service.dart';
import 'package:scholar_lens/services/tutor_service.dart';
import 'dart:io';
import 'dart:async';
class MockNetworkService implements NetworkService {
  bool _isConnected = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  void simulateNetworkFailure() {
    _isConnected = false;
    _connectivityController.add(false);
  }
  void simulateNetworkRestore() {
    _isConnected = true;
    _connectivityController.add(true);
  }
  @override
  Future<bool> checkConnectivity() async {
    return _isConnected;
  }
  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }
  @override
  Future<void> activateOfflineMode() async {
  }
  @override
  Future<void> deactivateOfflineMode() async {
  }
  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;
  @override
  NetworkError detectNetworkError(dynamic error) {
    return NetworkError(
      type: NetworkErrorType.noConnection,
      message: 'Mock network error',
    );
  }
  @override
  void dispose() {
    _connectivityController.close();
  }
  @override
  Future<void> handleNetworkError(NetworkError error) async {}
  @override
  Future<T> retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3, Duration initialDelay = const Duration(seconds: 1)}) async {
    return await operation();
  }
  @override
  void startMonitoring() {}
  @override
  void stopMonitoring() {}
}
class MockOfflineServiceWithTransitions implements OfflineService {
  bool _isOfflineMode = false;
  final StreamController<bool> _offlineModeController = StreamController<bool>.broadcast();
  @override
  Future<LessonContent> getDemoLesson() async {
    return LessonContent(
      lessonTitle: 'Offline Demo: Photosynthesis Basics',
      summaryMarkdown: '''# Photosynthesis - Offline Mode
## What is Photosynthesis?
Photosynthesis is the process by which plants convert sunlight into energy.
## Key Components:
- **Chlorophyll**: Green pigment that captures light
- **Carbon Dioxide**: Absorbed from air through stomata
- **Water**: Absorbed through roots
- **Sunlight**: Energy source for the reaction
## The Process:
1. Light absorption by chlorophyll
2. Water splitting to release oxygen
3. Carbon dioxide fixation
4. Glucose production
*This is a demo lesson available offline.*''',
      audioTranscript: 'Photosynthesis is the process by which plants convert sunlight into energy. This involves chlorophyll capturing light, water being split to release oxygen, carbon dioxide being fixed, and glucose being produced.',
      quiz: [
        QuizQuestion(
          question: 'What is the main purpose of photosynthesis?',
          options: [
            'Convert sunlight to energy',
            'Absorb water from soil',
            'Release carbon dioxide',
            'Grow plant roots'
          ],
          correctIndex: 0,
          explanation: 'Photosynthesis converts sunlight into chemical energy (glucose) that plants can use.',
        ),
        QuizQuestion(
          question: 'Which pigment is responsible for capturing light in photosynthesis?',
          options: [
            'Carotene',
            'Chlorophyll',
            'Anthocyanin',
            'Xanthophyll'
          ],
          correctIndex: 1,
          explanation: 'Chlorophyll is the green pigment that captures light energy for photosynthesis.',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }
  @override
  bool get isOfflineMode => _isOfflineMode;
  @override
  Future<void> activateOfflineMode() async {
    _isOfflineMode = true;
    _offlineModeController.add(true);
  }
  @override
  Future<void> deactivateOfflineMode() async {
    _isOfflineMode = false;
    _offlineModeController.add(false);
  }
  @override
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  @override
  Future<bool> checkNetworkConnectivity() async => !_isOfflineMode;
  @override
  void dispose() {
    _offlineModeController.close();
  }
  @override
  Future<List<String>> getAvailableDemoLessons() async => ['Offline Demo: Photosynthesis Basics'];
  @override
  Future<LessonContent?> getDemoLessonByTitle(String title) async {
    if (title.contains('Photosynthesis')) {
      return await getDemoLesson();
    }
    return null;
  }
}
class MockTutorServiceWithFailure implements TutorService {
  bool _shouldFail = false;
  void simulateNetworkFailure() {
    _shouldFail = true;
  }
  void simulateNetworkRestore() {
    _shouldFail = false;
  }
  @override
  Future<LessonContent> analyzeImage(File image, {String? userPrompt}) async {
    if (_shouldFail) {
      throw Exception('Network error: Unable to connect to server');
    }
    await Future.delayed(Duration(milliseconds: 500));
    return LessonContent(
      lessonTitle: 'Online Lesson: Advanced Photosynthesis',
      summaryMarkdown: '# Advanced Photosynthesis\n\nDetailed analysis of the photosynthesis process with online AI insights.',
      audioTranscript: 'This is an advanced lesson about photosynthesis with AI-generated insights.',
      quiz: [
        QuizQuestion(
          question: 'What happens during the light-dependent reactions?',
          options: ['ATP production', 'Glucose synthesis', 'Root growth', 'Leaf formation'],
          correctIndex: 0,
          explanation: 'Light-dependent reactions produce ATP and NADPH.',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }
  @override
  Future<String> askFollowUpQuestion(String question, String context) async {
    if (_shouldFail) {
      throw Exception('Network error: Unable to connect to server');
    }
    return 'Online AI response to: $question';
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
    if (_shouldFail) {
      throw Exception('Network error: Unable to connect to server');
    }
    return 'Online chapter response for: $question in $textbookTitle Chapter $chapterNumber';
  }
  @override
  Future<bool> isServiceAvailable() async {
    return !_shouldFail;
  }
}
void main() {
  group('Offline Mode Integration Tests', () {
    late MockNetworkService mockNetworkService;
    late MockOfflineServiceWithTransitions mockOfflineService;
    late MockTutorServiceWithFailure mockTutorService;
    setUp(() {
      mockNetworkService = MockNetworkService();
      mockOfflineService = MockOfflineServiceWithTransitions();
      mockTutorService = MockTutorServiceWithFailure();
    });
    test('Network failure triggers offline mode activation', () async {
      expect(await mockNetworkService.checkConnectivity(), isTrue);
      expect(mockOfflineService.isOfflineMode, isFalse);
      mockNetworkService.simulateNetworkFailure();
      mockTutorService.simulateNetworkFailure();
      final tempFile = File('${Directory.systemTemp.path}/test.jpg');
      await tempFile.writeAsBytes([1, 2, 3, 4]);
      try {
        await mockTutorService.analyzeImage(tempFile);
        fail('Expected network error');
      } catch (e) {
        expect(e.toString(), contains('Network error'));
      }
      await mockOfflineService.activateOfflineMode();
      expect(mockOfflineService.isOfflineMode, isTrue);
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.lessonTitle, contains('Offline Demo'));
      expect(demoLesson.summaryMarkdown, contains('Offline Mode'));
      if (tempFile.existsSync()) await tempFile.delete();
    });
    test('Demo lesson loading and content validation', () async {
      await mockOfflineService.activateOfflineMode();
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.lessonTitle, equals('Offline Demo: Photosynthesis Basics'));
      expect(demoLesson.summaryMarkdown, contains('# Photosynthesis - Offline Mode'));
      expect(demoLesson.summaryMarkdown, contains('## What is Photosynthesis?'));
      expect(demoLesson.summaryMarkdown, contains('## Key Components:'));
      expect(demoLesson.summaryMarkdown, contains('## The Process:'));
      expect(demoLesson.audioTranscript, isNotEmpty);
      expect(demoLesson.audioTranscript, contains('Photosynthesis'));
      expect(demoLesson.audioTranscript, contains('chlorophyll'));
      expect(demoLesson.quiz.length, equals(2));
      final firstQuestion = demoLesson.quiz[0];
      expect(firstQuestion.question, contains('main purpose of photosynthesis'));
      expect(firstQuestion.options.length, equals(4));
      expect(firstQuestion.correctIndex, equals(0));
      expect(firstQuestion.explanation, contains('converts sunlight'));
      final secondQuestion = demoLesson.quiz[1];
      expect(secondQuestion.question, contains('pigment'));
      expect(secondQuestion.options.length, equals(4));
      expect(secondQuestion.correctIndex, equals(1));
      expect(secondQuestion.explanation, contains('Chlorophyll'));
    });
    test('Network restoration and online mode transition', () async {
      mockNetworkService.simulateNetworkFailure();
      mockTutorService.simulateNetworkFailure();
      await mockOfflineService.activateOfflineMode();
      expect(mockOfflineService.isOfflineMode, isTrue);
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.lessonTitle, contains('Offline Demo'));
      mockNetworkService.simulateNetworkRestore();
      mockTutorService.simulateNetworkRestore();
      await mockOfflineService.deactivateOfflineMode();
      expect(mockOfflineService.isOfflineMode, isFalse);
      expect(await mockNetworkService.checkConnectivity(), isTrue);
      final tempFile = File('${Directory.systemTemp.path}/test_online.jpg');
      await tempFile.writeAsBytes([1, 2, 3, 4]);
      final onlineLesson = await mockTutorService.analyzeImage(tempFile);
      expect(onlineLesson.lessonTitle, contains('Online Lesson'));
      expect(onlineLesson.summaryMarkdown, contains('online AI insights'));
      if (tempFile.existsSync()) await tempFile.delete();
    });
    test('Offline mode user experience flow', () async {
      final testFile = File('${Directory.systemTemp.path}/user_test.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);
      final onlineLesson = await mockTutorService.analyzeImage(testFile);
      expect(onlineLesson.lessonTitle, contains('Online Lesson'));
      mockNetworkService.simulateNetworkFailure();
      mockTutorService.simulateNetworkFailure();
      try {
        await mockTutorService.analyzeImage(testFile);
        fail('Should have failed due to network error');
      } catch (e) {
        expect(e.toString(), contains('Network error'));
      }
      await mockOfflineService.activateOfflineMode();
      expect(mockOfflineService.isOfflineMode, isTrue);
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.lessonTitle, contains('Offline Demo'));
      expect(demoLesson.quiz.length, greaterThan(0));
      final quiz = demoLesson.quiz.first;
      expect(quiz.options.length, equals(4));
      expect(quiz.correctIndex, lessThan(quiz.options.length));
      mockNetworkService.simulateNetworkRestore();
      mockTutorService.simulateNetworkRestore();
      await mockOfflineService.deactivateOfflineMode();
      final retryLesson = await mockTutorService.analyzeImage(testFile);
      expect(retryLesson.lessonTitle, contains('Online Lesson'));
      if (testFile.existsSync()) await testFile.delete();
    });
    test('Offline mode chat functionality', () async {
      final onlineResponse = await mockTutorService.askFollowUpQuestion('What is photosynthesis?', 'lesson context');
      expect(onlineResponse, contains('Online AI response'));
      mockNetworkService.simulateNetworkFailure();
      mockTutorService.simulateNetworkFailure();
      await mockOfflineService.activateOfflineMode();
      try {
        await mockTutorService.askFollowUpQuestion('Follow up question', 'context');
        fail('Should have failed in offline mode');
      } catch (e) {
        expect(e.toString(), contains('Network error'));
      }
      final demoLesson = await mockOfflineService.getDemoLesson();
      expect(demoLesson.summaryMarkdown, isNotEmpty);
      expect(demoLesson.audioTranscript, isNotEmpty);
    });
  });
}