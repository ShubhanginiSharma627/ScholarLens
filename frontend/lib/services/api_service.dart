import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://scholarlens-afvx.onrender.com/api',
  );
  static const int _timeoutSeconds = 15; // Reduced from 30 to 15 seconds
  String? _accessToken;
  String? _refreshToken;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
  Map<String, String> get _multipartHeaders => {
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }
  http.Client get _client => http.Client();
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = customHeaders ?? _headers;
    if (requiresAuth && _accessToken == null) {
      throw ApiException('Authentication required', 401);
    }
    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers)
              .timeout(const Duration(seconds: _timeoutSeconds));
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: _timeoutSeconds));
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: _timeoutSeconds));
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers)
              .timeout(const Duration(seconds: _timeoutSeconds));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method', 400);
      }
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e', 0);
    }
  }
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Invalid JSON response', response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    if (response.statusCode == 401 && _refreshToken != null) {
      throw TokenExpiredException(
        data['error']?['message'] ?? 'Authentication failed',
        response.statusCode,
      );
    }
    throw ApiException(
      data['error']?['message'] ?? 'Request failed',
      response.statusCode,
    );
  }
  Future<Map<String, dynamic>> _makeMultipartRequest(
    String endpoint,
    Map<String, String> fields, {
    List<http.MultipartFile>? files,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (requiresAuth && _accessToken == null) {
      throw ApiException('Authentication required', 401);
    }
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders);
      request.fields.addAll(fields);
      if (files != null) {
        request.files.addAll(files);
      }
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: _timeoutSeconds * 2));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload failed: $e', 0);
    }
  }
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _makeRequest('POST', '/auth/register', body: {
      'email': email,
      'password': password,
      'name': name,
    });
    final authData = AuthResponse.fromJson(response['data']);
    setTokens(authData.tokens.accessToken, authData.tokens.refreshToken);
    return authData;
  }
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    final authData = AuthResponse.fromJson(response['data']);
    setTokens(authData.tokens.accessToken, authData.tokens.refreshToken);
    return authData;
  }
  Future<AuthResponse> googleSignIn({
    required String idToken,
    String clientType = 'android', // 'web', 'android', or 'ios'
  }) async {
    final response = await _makeRequest('POST', '/auth/google', body: {
      'idToken': idToken,
      'clientType': clientType,
    });
    final authData = AuthResponse.fromJson(response['data']);
    setTokens(authData.tokens.accessToken, authData.tokens.refreshToken);
    return authData;
  }
  Future<void> logout() async {
    await _makeRequest('POST', '/auth/logout', requiresAuth: true);
    clearTokens();
  }
  Future<AuthTokens> refreshTokens() async {
    if (_refreshToken == null) {
      throw ApiException('No refresh token available', 401);
    }
    final response = await _makeRequest('POST', '/auth/refresh', body: {
      'refreshToken': _refreshToken,
    });
    final tokens = AuthTokens.fromJson(response['data']['tokens']);
    setTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }
  Future<List<Flashcard>> getFlashcards({
    String? setId,
    String? tags,
    String? difficulty,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (setId != null) 'setId': setId,
      if (tags != null) 'tags': tags,
      if (difficulty != null) 'difficulty': difficulty,
    };
    final uri = Uri.parse('$_baseUrl/flashcards')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
    final data = _handleResponse(response);
    final flashcardsJson = data['data']['flashcards'] as List;
    return flashcardsJson.map((json) => Flashcard.fromJson(json)).toList();
  }
  Future<Flashcard> createFlashcard({
    required String question,
    required String answer,
    String difficulty = 'medium',
    List<String> tags = const [],
    String? setId,
  }) async {
    final response = await _makeRequest('POST', '/flashcards', 
      requiresAuth: true,
      body: {
        'question': question,
        'answer': answer,
        'difficulty': difficulty,
        'tags': tags,
        if (setId != null) 'setId': setId,
      },
    );
    return Flashcard.fromJson(response['data']['flashcard']);
  }
  Future<List<Flashcard>> generateFlashcards({
    required String topic,
    int count = 5,
    String difficulty = 'medium',
    String? setId,
  }) async {
    final response = await _makeRequest('POST', '/flashcards/generate',
      requiresAuth: true,
      body: {
        'topic': topic,
        'count': count,
        'difficulty': difficulty,
        if (setId != null) 'setId': setId,
      },
    );
    final flashcardsJson = response['data']['flashcards'] as List;
    return flashcardsJson.map((json) => Flashcard.fromJson(json)).toList();
  }
  Future<void> studyFlashcard({
    required String flashcardId,
    required bool correct,
    int? timeSpent,
  }) async {
    await _makeRequest('POST', '/flashcards/study',
      requiresAuth: true,
      body: {
        'flashcardId': flashcardId,
        'correct': correct,
        if (timeSpent != null) 'timeSpent': timeSpent,
      },
    );
  }
  Future<String> analyzeImage({
    required String imageBase64,
    String? prompt,
    String mimeType = 'image/jpeg',
  }) async {
    final response = await _makeRequest('POST', '/vision/scan', body: {
      'image': imageBase64,
      'prompt': prompt ?? 'Analyze this image and explain any diagrams, math, or text.',
      'mimeType': mimeType,
    });
    return response['analysis'] as String;
  }
  Future<String> generateStudyPlan({
    required String topic,
    String audience = 'general',
    String length = 'short',
    String constraints = '',
  }) async {
    final response = await _makeRequest('POST', '/generate-plan', body: {
      'topic': topic,
      'audience': audience,
      'length': length,
      'constraints': constraints,
    });
    return response['data'] as String;
  }
  Future<String> explainTopic({
    required String topic,
    String audience = 'student',
    String type = 'concise',
  }) async {
    final response = await _makeRequest('POST', '/explain-topic', body: {
      'topic': topic,
      'audience': audience,
      'type': type,
    });
    return response['data'] as String;
  }
  Future<Map<String, dynamic>> explainTopicEnhanced({
    required String topic,
    String audience = 'student',
    String type = 'detailed',
    String? context,
    String? variation,
  }) async {
    final response = await _makeRequest('POST', '/ai/explain',
      requiresAuth: true,
      body: {
        'topic': topic,
        'audience': audience,
        'type': type,
        if (context != null) 'context': context,
        if (variation != null) 'variation': variation,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> generateStudyPlanEnhanced({
    required List<String> subjects,
    Map<String, String>? examDates,
    Map<String, dynamic>? availableTime,
    String currentLevel = 'intermediate',
    Map<String, dynamic>? studyPreferences,
    List<String>? goals,
    String? constraints,
  }) async {
    final response = await _makeRequest('POST', '/ai/study-plan',
      requiresAuth: true,
      body: {
        'subjects': subjects,
        if (examDates != null) 'examDates': examDates,
        if (availableTime != null) 'availableTime': availableTime,
        'currentLevel': currentLevel,
        if (studyPreferences != null) 'studyPreferences': studyPreferences,
        if (goals != null) 'goals': goals,
        if (constraints != null) 'constraints': constraints,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> generateRevisionPlan({
    required String topic,
    String audience = 'student',
    String length = 'comprehensive',
    String? constraints,
  }) async {
    final response = await _makeRequest('POST', '/ai/revision-plan',
      requiresAuth: true,
      body: {
        'topic': topic,
        'audience': audience,
        'length': length,
        if (constraints != null) 'constraints': constraints,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> chatWithTutor({
    required String message,
    String? subject,
    String? studentLevel,
    List<Map<String, dynamic>>? conversationHistory,
    List<String>? learningGoals,
    String sessionType = 'general_chat',
  }) async {
    final response = await _makeRequest('POST', '/ai/chat',
      requiresAuth: true,
      body: {
        'message': message,
        if (subject != null) 'subject': subject,
        if (studentLevel != null) 'studentLevel': studentLevel,
        if (conversationHistory != null) 'conversationHistory': conversationHistory,
        if (learningGoals != null) 'learningGoals': learningGoals,
        'sessionType': sessionType,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> analyzeSyllabus({
    required String syllabusContent,
    String? courseLevel,
    String? subjectArea,
    String analysisType = 'structure_extraction',
    String? semesterLength,
  }) async {
    final response = await _makeRequest('POST', '/ai/analyze-syllabus',
      requiresAuth: true,
      body: {
        'syllabusContent': syllabusContent,
        if (courseLevel != null) 'courseLevel': courseLevel,
        if (subjectArea != null) 'subjectArea': subjectArea,
        'analysisType': analysisType,
        if (semesterLength != null) 'semesterLength': semesterLength,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> analyzeEducationalImage({
    required String imageData,
    String analysisType = 'general',
    String? subject,
    String language = 'English',
    String? difficulty,
  }) async {
    final response = await _makeRequest('POST', '/ai/analyze-image',
      requiresAuth: true,
      body: {
        'imageData': imageData,
        'analysisType': analysisType,
        if (subject != null) 'subject': subject,
        'language': language,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> generateQuizQuestions({
    required String topic,
    int count = 5,
    String type = 'multiple_choice',
    String? subject,
    String? difficulty,
  }) async {
    final response = await _makeRequest('POST', '/ai/generate-quiz',
      requiresAuth: true,
      body: {
        'topic': topic,
        'count': count,
        'type': type,
        if (subject != null) 'subject': subject,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    return response['data'];
  }
  Future<Map<String, dynamic>> getAIStatus() async {
    final response = await _makeRequest('GET', '/ai/status');
    return response['data'];
  }
  Future<UserStats> getUserStats() async {
    final response = await _makeRequest('GET', '/stats', requiresAuth: true);
    return UserStats.fromJson(response);
  }
  Future<Map<String, dynamic>> getStorageStatus() async {
    final response = await _makeRequest('GET', '/storage/status');
    return response['data'];
  }
  Future<StorageUploadResponse> uploadFile({
    required File file,
    String? folder,
    bool makePublic = false,
  }) async {
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: file.path.split('/').last,
    );
    final fields = <String, String>{
      if (folder != null) 'folder': folder,
      'makePublic': makePublic.toString(),
    };
    final response = await _makeMultipartRequest(
      '/storage/upload',
      fields,
      files: [multipartFile],
      requiresAuth: true,
    );
    return StorageUploadResponse.fromJson(response['data']);
  }
  Future<String> getFileDownloadUrl({
    required String fileName,
    DateTime? expires,
    bool public = false,
  }) async {
    final queryParams = <String, String>{
      if (expires != null) 'expires': expires.toIso8601String(),
      'public': public.toString(),
    };
    final uri = Uri.parse('$_baseUrl/storage/download/$fileName')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
    final data = _handleResponse(response);
    return data['data']['downloadUrl'] as String;
  }
  Future<void> deleteFile({required String fileName}) async {
    await _makeRequest('DELETE', '/storage/files/$fileName', requiresAuth: true);
  }
  Future<List<StorageFile>> listFiles({
    String? folder,
    int maxResults = 100,
  }) async {
    final queryParams = <String, String>{
      if (folder != null) 'folder': folder,
      'maxResults': maxResults.toString(),
    };
    final uri = Uri.parse('$_baseUrl/storage/files')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
    final data = _handleResponse(response);
    final filesJson = data['data']['files'] as List;
    return filesJson.map((json) => StorageFile.fromJson(json)).toList();
  }
  Future<Map<String, dynamic>> scanSyllabus({
    required File file,
    String? prompt,
  }) async {
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: file.path.split('/').last,
    );
    final fields = <String, String>{
      if (prompt != null) 'prompt': prompt,
    };
    final response = await _makeMultipartRequest(
      '/syllabus/scan',
      fields,
      files: [multipartFile],
      requiresAuth: true,
    );
    return response;
  }
  void dispose() {
    _client.close();
  }
}
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
class TokenExpiredException extends ApiException {
  TokenExpiredException(String message, int statusCode) 
      : super(message, statusCode);
}
class AuthResponse {
  final User user;
  final AuthTokens tokens;
  AuthResponse({required this.user, required this.tokens});
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      tokens: AuthTokens.fromJson(json['tokens']),
    );
  }
}
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  AuthTokens({required this.accessToken, required this.refreshToken});
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> profile;
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.preferences,
    required this.profile,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      preferences: json['preferences'] ?? {},
      profile: json['profile'] ?? {},
    );
  }
}
class UserStats {
  final int totalInteractions;
  final Map<String, int> topics;
  final List<double> quizScores;
  final int streak;
  final List<WeakTopic> weakestTopics;
  UserStats({
    required this.totalInteractions,
    required this.topics,
    required this.quizScores,
    required this.streak,
    required this.weakestTopics,
  });
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalInteractions: json['totalInteractions'] ?? 0,
      topics: Map<String, int>.from(json['topics'] ?? {}),
      quizScores: List<double>.from(json['quizScores'] ?? []),
      streak: json['streak'] ?? 0,
      weakestTopics: (json['weakestTopics'] as List? ?? [])
          .map((item) => WeakTopic.fromJson(item))
          .toList(),
    );
  }
}
class WeakTopic {
  final String topic;
  final int count;
  WeakTopic({required this.topic, required this.count});
  factory WeakTopic.fromJson(Map<String, dynamic> json) {
    return WeakTopic(
      topic: json['topic'],
      count: json['count'],
    );
  }
}