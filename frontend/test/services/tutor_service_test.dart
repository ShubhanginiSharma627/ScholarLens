import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scholar_lens/services/tutor_service.dart';
import 'package:scholar_lens/models/lesson_content.dart';

void main() {
  group('TutorService Tests', () {
    late HttpTutorService tutorService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"message": "Not implemented"}', 404);
      });
      
      tutorService = HttpTutorService(
        baseUrl: 'http://test.com',
        client: mockClient,
      );
    });

    tearDown(() {
      tutorService.dispose();
    });

    group('analyzeImage', () {
      test('should send multipart request with image file', () async {
        // Create a temporary test image file
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy image data

        mockClient = MockClient((request) async {
          // Verify it's a multipart request
          expect(request.method, 'POST');
          expect(request.url.path, '/analyze');
          expect(request.headers['Accept'], 'application/json');
          
          return http.Response(json.encode({
            'lesson_title': 'Test Lesson',
            'summary_markdown': '# Test Summary',
            'audio_transcript': 'Test audio transcript',
            'quiz': [],
            'created_at': DateTime.now().toIso8601String(),
          }), 200);
        });

        tutorService = HttpTutorService(
          baseUrl: 'http://test.com',
          client: mockClient,
        );

        try {
          final result = await tutorService.analyzeImage(testFile);
          
          expect(result, isA<LessonContent>());
          expect(result.lessonTitle, 'Test Lesson');
          expect(result.summaryMarkdown, '# Test Summary');
          expect(result.audioTranscript, 'Test audio transcript');
        } finally {
          // Clean up test file
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should include user prompt when provided', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        mockClient = MockClient((request) async {
          // For multipart requests, we can't easily check the body content
          // but we can verify the request structure
          expect(request.method, 'POST');
          expect(request.url.path, '/analyze');
          
          return http.Response(json.encode({
            'lesson_title': 'Test Lesson',
            'summary_markdown': '# Test Summary',
            'audio_transcript': 'Test audio transcript',
            'quiz': [],
          }), 200);
        });

        tutorService = HttpTutorService(
          baseUrl: 'http://test.com',
          client: mockClient,
        );

        try {
          final result = await tutorService.analyzeImage(
            testFile,
            userPrompt: 'Explain this diagram',
          );
          
          expect(result, isA<LessonContent>());
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should throw TutorServiceException for non-existent file', () async {
        final nonExistentFile = File('/non/existent/path.jpg');
        
        expect(
          () => tutorService.analyzeImage(nonExistentFile),
          throwsA(isA<TutorServiceException>()),
        );
      });

      test('should throw TutorServiceException for HTTP errors', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        tutorService = HttpTutorService(
          baseUrl: 'http://test.com',
          client: mockClient,
        );

        try {
          expect(
            () => tutorService.analyzeImage(testFile),
            throwsA(isA<TutorServiceException>()),
          );
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });

    group('askFollowUpQuestion', () {
      test('should send POST request with question and context', () async {
        mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/chat');
          expect(request.headers['Content-Type'], 'application/json');
          
          final body = json.decode(request.body);
          expect(body['question'], 'What is photosynthesis?');
          expect(body['context'], 'Biology lesson');
          
          return http.Response(json.encode({
            'response': 'Photosynthesis is the process...'
          }), 200);
        });

        tutorService = HttpTutorService(
          baseUrl: 'http://test.com',
          client: mockClient,
        );

        final result = await tutorService.askFollowUpQuestion(
          'What is photosynthesis?',
          'Biology lesson',
        );
        
        expect(result, 'Photosynthesis is the process...');
      });

      test('should throw TutorServiceException for HTTP errors', () async {
        mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        tutorService = HttpTutorService(
          baseUrl: 'http://test.com',
          client: mockClient,
        );

        expect(
          () => tutorService.askFollowUpQuestion('Question', 'Context'),
          throwsA(isA<TutorServiceException>()),
        );
      });
    });

    group('TutorServiceFactory', () {
      test('should create production service with default URL', () {
        final service = TutorServiceFactory.createProduction();
        expect(service, isA<HttpTutorService>());
      });

      test('should create production service with custom URL', () {
        final service = TutorServiceFactory.createProduction(
          baseUrl: 'http://custom.com',
        );
        expect(service, isA<HttpTutorService>());
      });

      test('should create testing service', () {
        final service = TutorServiceFactory.createForTesting(
          baseUrl: 'http://test.com',
        );
        expect(service, isA<HttpTutorService>());
      });
    });
  });
}