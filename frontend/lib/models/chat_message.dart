class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? structuredData;
  
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.status,
    this.structuredData,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      structuredData: json['structured_data'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      if (structuredData != null) 'structured_data': structuredData,
    };
  }
  
  factory ChatMessage.user({
    required String content,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${now.millisecondsSinceEpoch}',
      content: content,
      isUser: true,
      timestamp: now,
      status: MessageStatus.sending,
    );
  }
  
  factory ChatMessage.ai({
    required String content,
    Map<String, dynamic>? structuredData,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${now.millisecondsSinceEpoch}',
      content: content,
      isUser: false,
      timestamp: now,
      status: MessageStatus.delivered,
      structuredData: structuredData,
    );
  }
  
  List<String> get followUpQuestions => 
      (structuredData?['followUpQuestions'] as List<dynamic>?)?.cast<String>() ?? [];
  
  List<String> get keyConcepts => 
      (structuredData?['keyConcepts'] as List<dynamic>?)?.cast<String>() ?? [];
  
  String get sessionSummary => 
      structuredData?['sessionSummary'] as String? ?? '';
  
  List<String> get suggestedTopics => 
      (structuredData?['suggestedTopics'] as List<dynamic>?)?.cast<String>() ?? [];
  
  List<String> get studyTips => 
      (structuredData?['studyTips'] as List<dynamic>?)?.cast<String>() ?? [];
  
  Map<String, dynamic> get encouragement => 
      structuredData?['encouragement'] as Map<String, dynamic>? ?? {};
  
  String get responseType => 
      structuredData?['responseType'] as String? ?? 'general';
  
  String get difficultyLevel => 
      structuredData?['difficultyLevel'] as String? ?? 'medium';
  
  bool get hasStructuredData => structuredData != null;
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '${timestamp.day}/${timestamp.month} $hour:$minute';
    }
  }
  String get senderLabel => isUser ? 'You' : 'AI Tutor';
  bool get hasFailed => status == MessageStatus.failed;
  bool get isSending => status == MessageStatus.sending;
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? structuredData,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      structuredData: structuredData ?? this.structuredData,
    );
  }
  ChatMessage updateStatus(MessageStatus newStatus) {
    return copyWith(status: newStatus);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.structuredData == structuredData;
  }
  @override
  int get hashCode {
    return Object.hash(id, content, isUser, timestamp, status, structuredData);
  }
  @override
  String toString() {
    return 'ChatMessage(id: $id, isUser: $isUser, status: $status, content: ${content.length} chars, hasStructuredData: $hasStructuredData)';
  }
}
enum MessageStatus {
  sending('Sending'),
  sent('Sent'),
  delivered('Delivered'),
  failed('Failed');
  const MessageStatus(this.displayName);
  final String displayName;
}