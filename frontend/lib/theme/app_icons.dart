import 'package:flutter/material.dart';

/// Consistent icon system for ScholarLens app
class AppIcons {
  // Navigation icons
  static const IconData home = Icons.home_rounded;
  static const IconData tutor = Icons.psychology_rounded;
  static const IconData cards = Icons.style_rounded;
  static const IconData profile = Icons.person_rounded;
  
  // Action icons
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData microphone = Icons.mic_rounded;
  static const IconData microphoneOff = Icons.mic_off_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData cancel = Icons.cancel_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData close = Icons.close_rounded;
  
  // Audio controls
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData stop = Icons.stop_rounded;
  static const IconData volumeUp = Icons.volume_up_rounded;
  static const IconData volumeOff = Icons.volume_off_rounded;
  
  // Learning icons
  static const IconData quiz = Icons.quiz_rounded;
  static const IconData lesson = Icons.menu_book_rounded;
  static const IconData flashcard = Icons.style_rounded;
  static const IconData progress = Icons.trending_up_rounded;
  static const IconData achievement = Icons.emoji_events_rounded;
  static const IconData streak = Icons.local_fire_department_rounded;
  static const IconData time = Icons.access_time_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  
  // Subject icons
  static const IconData math = Icons.calculate_rounded;
  static const IconData science = Icons.science_rounded;
  static const IconData history = Icons.history_edu_rounded;
  static const IconData language = Icons.translate_rounded;
  static const IconData art = Icons.palette_rounded;
  static const IconData music = Icons.music_note_rounded;
  static const IconData sports = Icons.sports_basketball_rounded;
  static const IconData computer = Icons.computer_rounded;
  
  // Status icons
  static const IconData online = Icons.wifi_rounded;
  static const IconData offline = Icons.wifi_off_rounded;
  static const IconData loading = Icons.hourglass_empty_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData success = Icons.check_circle_rounded;
  static const IconData info = Icons.info_rounded;
  
  // Settings icons
  static const IconData settings = Icons.settings_rounded;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData notificationsOff = Icons.notifications_off_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData languageSettings = Icons.language_rounded;
  static const IconData help = Icons.help_rounded;
  static const IconData feedback = Icons.feedback_rounded;
  static const IconData logout = Icons.logout_rounded;
  
  // Navigation arrows
  static const IconData arrowBack = Icons.arrow_back_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData arrowUp = Icons.keyboard_arrow_up_rounded;
  static const IconData arrowDown = Icons.keyboard_arrow_down_rounded;
  static const IconData arrowLeft = Icons.keyboard_arrow_left_rounded;
  static const IconData arrowRight = Icons.keyboard_arrow_right_rounded;
  
  // Difficulty levels
  static const IconData easy = Icons.sentiment_satisfied_rounded;
  static const IconData medium = Icons.sentiment_neutral_rounded;
  static const IconData hard = Icons.sentiment_dissatisfied_rounded;
  
  // Chat icons
  static const IconData chat = Icons.chat_rounded;
  static const IconData message = Icons.message_rounded;
  static const IconData attach = Icons.attach_file_rounded;
  static const IconData emoji = Icons.emoji_emotions_rounded;
  
  // More icons
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData moreVert = Icons.more_vert_rounded;
  static const IconData menu = Icons.menu_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_border_rounded;
  static const IconData bookmark = Icons.bookmark_rounded;
  static const IconData bookmarkOutline = Icons.bookmark_border_rounded;
  
  // File icons
  static const IconData file = Icons.description_rounded;
  static const IconData image = Icons.image_rounded;
  static const IconData video = Icons.videocam_rounded;
  static const IconData audio = Icons.audiotrack_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  
  // Utility method to get subject icon by name
  static IconData getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
      case 'algebra':
      case 'geometry':
      case 'calculus':
        return math;
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return science;
      case 'history':
      case 'social studies':
        return history;
      case 'english':
      case 'language':
      case 'literature':
        return language;
      case 'art':
      case 'drawing':
      case 'painting':
        return art;
      case 'music':
        return music;
      case 'sports':
      case 'physical education':
      case 'pe':
        return sports;
      case 'computer':
      case 'programming':
      case 'coding':
      case 'technology':
        return computer;
      default:
        return lesson;
    }
  }
  
  // Utility method to get difficulty icon
  static IconData getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return easy;
      case 'medium':
        return medium;
      case 'hard':
        return hard;
      default:
        return medium;
    }
  }
  
  // Utility method to get status icon
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'done':
        return success;
      case 'error':
      case 'failed':
        return error;
      case 'warning':
        return warning;
      case 'loading':
      case 'pending':
        return loading;
      case 'info':
      case 'information':
        return info;
      default:
        return info;
    }
  }
}