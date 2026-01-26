import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/models.dart';

/// Provider for managing chat conversations with the AI tutor
class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;

  /// Initialize chat history from persistent storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJson = prefs.getString('chat_history');
      
      if (chatJson != null) {
        final chatList = json.decode(chatJson) as List<dynamic>;
        _messages = chatList
            .map((messageMap) => ChatMessage.fromJson(messageMap as Map<String, dynamic>))
            .toList();
      } else {
        _messages = [];
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to load chat history: $e');
      _messages = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Save chat history to persistent storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJson = json.encode(_messages.map((message) => message.toJson()).toList());
      await prefs.setString('chat_history', chatJson);
    } catch (e) {
      _setError('Failed to save chat history: $e');
    }
  }

  /// Add a new message to the conversation
  Future<void> addMessage(ChatMessage message) async {
    _messages.add(message);
    notifyListeners();
    await _saveChatHistory();
  }

  /// Send a user message
  Future<ChatMessage> sendUserMessage(String content) async {
    final userMessage = ChatMessage.user(content: content);
    await addMessage(userMessage);
    return userMessage;
  }

  /// Add an AI response message
  Future<void> addAIResponse(String content) async {
    final aiMessage = ChatMessage.ai(content: content);
    await addMessage(aiMessage);
  }

  /// Update a message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final messageIndex = _messages.indexWhere((message) => message.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].updateStatus(status);
      notifyListeners();
      await _saveChatHistory();
    }
  }

  /// Update a message content
  Future<void> updateMessage(String messageId, ChatMessage updatedMessage) async {
    final messageIndex = _messages.indexWhere((message) => message.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = updatedMessage;
      notifyListeners();
      await _saveChatHistory();
    }
  }

  /// Remove a message
  Future<void> removeMessage(String messageId) async {
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
    await _saveChatHistory();
  }

  /// Clear all messages
  Future<void> clearMessages() async {
    _messages.clear();
    notifyListeners();
    await _saveChatHistory();
  }

  /// Get messages from a specific date
  List<ChatMessage> getMessagesFromDate(DateTime date) {
    return _messages.where((message) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return messageDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// Get recent messages (last N messages)
  List<ChatMessage> getRecentMessages(int count) {
    if (_messages.length <= count) return _messages;
    return _messages.sublist(_messages.length - count);
  }

  /// Get user messages only
  List<ChatMessage> getUserMessages() {
    return _messages.where((message) => message.isUser).toList();
  }

  /// Get AI messages only
  List<ChatMessage> getAIMessages() {
    return _messages.where((message) => !message.isUser).toList();
  }

  /// Get failed messages
  List<ChatMessage> getFailedMessages() {
    return _messages.where((message) => message.hasFailed).toList();
  }

  /// Retry failed messages
  Future<List<ChatMessage>> retryFailedMessages() async {
    final failedMessages = getFailedMessages();
    
    for (final message in failedMessages) {
      await updateMessageStatus(message.id, MessageStatus.sending);
    }
    
    return failedMessages;
  }

  /// Set sending state
  void setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  /// Get conversation context for AI (last few messages)
  String getConversationContext({int maxMessages = 10}) {
    final recentMessages = getRecentMessages(maxMessages);
    final contextBuffer = StringBuffer();
    
    for (final message in recentMessages) {
      final sender = message.isUser ? 'User' : 'AI';
      contextBuffer.writeln('$sender: ${message.content}');
    }
    
    return contextBuffer.toString();
  }

  /// Search messages by content
  List<ChatMessage> searchMessages(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _messages.where((message) {
      return message.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get message statistics
  Map<String, dynamic> getMessageStats() {
    final userMessages = getUserMessages();
    final aiMessages = getAIMessages();
    final failedMessages = getFailedMessages();
    
    return {
      'total_messages': _messages.length,
      'user_messages': userMessages.length,
      'ai_messages': aiMessages.length,
      'failed_messages': failedMessages.length,
      'success_rate': _messages.isNotEmpty 
          ? ((_messages.length - failedMessages.length) / _messages.length * 100).round()
          : 100,
    };
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}