import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/common/top_navigation_bar.dart';
import '../services/tutor_service.dart';

/// Screen for chat interface with AI tutor
class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({super.key});

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late TutorService _tutorService;

  // Suggested topics
  final List<String> _suggestedTopics = [
    "Explain the mitochondria's role in cellular respiration",
    "Help me understand quadratic equations",
    "What's the difference between velocity and acceleration?",
    "Guide me through photosynthesis",
  ];

  @override
  void initState() {
    super.initState();
    _tutorService = TutorServiceFactory.createProduction();
    
    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    
    try {
      // Clear input
      _textController.clear();
      
      // Send user message
      chatProvider.setSending(true);
      final userMessage = await chatProvider.sendUserMessage(content);
      
      // Scroll to bottom after adding user message
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      
      // Get conversation context for AI
      final context = chatProvider.getConversationContext();
      
      // Get AI response
      final aiResponse = await _tutorService.askFollowUpQuestion(content, context);
      
      // Update user message status to delivered
      await chatProvider.updateMessageStatus(userMessage.id, MessageStatus.delivered);
      
      // Add AI response
      await chatProvider.addAIResponse(aiResponse);
      
      // Scroll to bottom after adding AI response
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      
    } catch (e) {
      // Handle error - mark user message as failed
      final failedMessages = chatProvider.getFailedMessages();
      if (failedMessages.isNotEmpty) {
        await chatProvider.updateMessageStatus(
          failedMessages.last.id, 
          MessageStatus.failed,
        );
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendMessage(content),
            ),
          ),
        );
      }
    } finally {
      chatProvider.setSending(false);
    }
  }

  void _handleSuggestedTopic(String topic) {
    _textController.text = topic;
    _sendMessage(topic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TopNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            const Text(
              'AI Tutor',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Learn through guided discovery',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Chat area with fixed height
            _buildChatArea(),
            const SizedBox(height: 24),
            
            // Suggested Topics section (always visible)
            _buildSuggestedTopicsSection(),
            const SizedBox(height: 24),
            
            // How it works section (always visible)
            _buildHowItWorksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      height: 400, // Fixed height for chat area
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (chatProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading chat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => chatProvider.initialize(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!chatProvider.hasMessages) {
                  return _buildInitialMessage();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length + 1, // +1 for initial message
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildInitialMessage();
                    }
                    final message = chatProvider.messages[index - 1];
                    return ChatMessageWidget(
                      message: message,
                      onRetry: message.hasFailed 
                          ? () => _sendMessage(message.content)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          
          // Chat input (inside the chat area)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Ask me anything...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: chatProvider.isSending 
                            ? null 
                            : () => _sendMessage(_textController.text),
                        icon: chatProvider.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Hello! I'm your Socratic AI Tutor. Instead of giving you direct answers, I'll ask guiding questions to help you discover the solutions yourself. What would you like to explore today? 🎓",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTopicsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Suggested Topics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._suggestedTopics.map((topic) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _handleSuggestedTopic(topic),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'How it works',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'I use the Socratic method - instead of giving answers, I\'ll guide you with questions to help you discover solutions yourself. This builds deeper understanding!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}