// Core data models for ScholarLens
export 'app_state.dart';
export 'auth_result.dart';
export 'chapter_section.dart';
export 'chat_message.dart';
export 'flashcard.dart';
export 'learning_session.dart';
export 'lesson_content.dart';
export 'processed_image.dart';
export 'quiz_question.dart';
export 'recent_activity.dart';
export 'recent_snap.dart';
export 'storage_file.dart';
export 'storage_upload_response.dart';
export 'study_session_progress.dart';
export 'text_highlight.dart';
export 'uploaded_textbook.dart';
export 'user.dart';
export 'user_progress.dart';

// AI Flashcard Generation models
export 'ai_generation.dart';

// Re-export auth error types from services
export '../services/auth_error_handler.dart' show AuthErrorInfo, UserAction, UserActionType;