import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class EnhancedChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onFollowUpTap;

  const EnhancedChatMessageWidget({
    super.key,
    required this.message,
    this.onFollowUpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: message.isUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          _buildMainMessage(context),
          if (!message.isUser && message.hasStructuredData) ...[
            const SizedBox(height: 12),
            _buildStructuredContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMainMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isUser 
            ? Theme.of(context).primaryColor 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.senderLabel,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.formattedTime,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              if (message.isSending) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      message.isUser ? Colors.white : Colors.grey[600]!,
                    ),
                  ),
                ),
              ],
              if (message.hasFailed) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red[400],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.keyConcepts.isNotEmpty) 
            _buildKeyConceptsSection(context),
          if (message.followUpQuestions.isNotEmpty) 
            _buildFollowUpQuestionsSection(context),
          if (message.studyTips.isNotEmpty) 
            _buildStudyTipsSection(context),
          if (message.sessionSummary.isNotEmpty) 
            _buildSessionSummarySection(context),
        ],
      ),
    );
  }

  Widget _buildKeyConceptsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, 
                   size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Key Concepts',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: message.keyConcepts.map((concept) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  concept,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpQuestionsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, 
                   size: 16, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Think About This',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...message.followUpQuestions.map((question) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.green[600])),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildStudyTipsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, 
                   size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Study Tips',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...message.studyTips.map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildSessionSummarySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_outlined, 
                   size: 16, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Session Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.sessionSummary,
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[800],
            ),
          ),
        ],
      ),
    );
  }
}