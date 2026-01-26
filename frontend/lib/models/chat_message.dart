/// Represents a chat message in the tutor conversation
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.status,
  });

  /// Creates a ChatMessage from JSON
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
    );
  }

  /// Converts ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  /// Creates a user message
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

  /// Creates an AI response message
  factory ChatMessage.ai({
    required String content,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${now.millisecondsSinceEpoch}',
      content: content,
      isUser: false,
      timestamp: now,
      status: MessageStatus.delivered,
    );
  }

  /// Gets formatted timestamp string
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

  /// Gets the sender label
  String get senderLabel => isUser ? 'You' : 'AI Tutor';

  /// Checks if the message failed to send
  bool get hasFailed => status == MessageStatus.failed;

  /// Checks if the message is still sending
  bool get isSending => status == MessageStatus.sending;

  /// Creates a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  /// Updates the message status
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
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, isUser, timestamp, status);
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, isUser: $isUser, status: $status, content: ${content.length} chars)';
  }
}

/// Status of a chat message
enum MessageStatus {
  sending('Sending'),
  sent('Sent'),
  delivered('Delivered'),
  failed('Failed');

  const MessageStatus(this.displayName);
  final String displayName;
}