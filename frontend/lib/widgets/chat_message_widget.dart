import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../animations/animation_manager.dart';
import '../animations/animation_config.dart';
class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final int? messageIndex;
  final bool enableStaggeredAnimation;
  final Duration? staggerDelay;
  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.messageIndex,
    this.enableStaggeredAnimation = true,
    this.staggerDelay,
  });
  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}
class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  late final AnimationManager _animationManager;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String? _slideAnimationId;
  String? _fadeAnimationId;
  bool _hasAnimated = false;
  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _initializeAnimations();
    final delay = widget.enableStaggeredAnimation && widget.messageIndex != null
        ? Duration(milliseconds: (widget.messageIndex! * 100).clamp(0, 500))
        : (widget.staggerDelay ?? Duration.zero);
    Future.delayed(delay, () {
      if (mounted && !_hasAnimated) {
        _startAnimation();
      }
    });
  }
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
    _createLocalAnimations();
  }
  void _registerAnimations() {
    try {
      final slideConfig = widget.message.isUser 
          ? AnimationConfigs.messageSlideInUser
          : AnimationConfigs.messageSlideInAI;
      _slideAnimationId = _animationManager.registerController(
        controller: _slideController,
        config: slideConfig,
        category: AnimationCategory.content,
      );
      final fadeConfig = AnimationConfigs.fadeTransition;
      _fadeAnimationId = _animationManager.registerController(
        controller: _fadeController,
        config: fadeConfig,
        category: AnimationCategory.content,
      );
      final slideAnim = _animationManager.getAnimation(_slideAnimationId!);
      final fadeAnim = _animationManager.getAnimation(_fadeAnimationId!);
      if (slideAnim != null && fadeAnim != null) {
        _slideAnimation = slideAnim.animation as Animation<Offset>;
        _fadeAnimation = fadeAnim.animation as Animation<double>;
      } else {
        _createLocalAnimations();
      }
    } catch (e) {
      debugPrint('Failed to register chat message animations: $e');
      _createLocalAnimations();
    }
  }
  void _createLocalAnimations() {
    final slideStart = widget.message.isUser 
        ? const Offset(0.3, 0.0)
        : const Offset(-0.3, 0.0);
    _slideAnimation = Tween<Offset>(
      begin: slideStart,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }
  void _startAnimation() {
    if (_hasAnimated || !mounted) return;
    _hasAnimated = true;
    if (_slideAnimationId != null && _fadeAnimationId != null) {
      _animationManager.startAnimation(_slideAnimationId!);
      _animationManager.startAnimation(_fadeAnimationId!);
    } else {
      _slideController.forward();
      _fadeController.forward();
    }
  }
  @override
  void dispose() {
    if (_slideAnimationId != null) {
      _animationManager.disposeController(_slideAnimationId!);
    }
    if (_fadeAnimationId != null) {
      _animationManager.disposeController(_fadeAnimationId!);
    }
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMessageContent(context),
          ),
        );
      },
    );
  }
  Widget _buildMessageContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: widget.message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) ...[
            _buildAvatar(context, false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: widget.message.isUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _getMessageColor(context),
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: widget.message.isUser 
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                          bottomLeft: !widget.message.isUser 
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.content,
                            style: TextStyle(
                              color: _getTextColor(context),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          if (widget.message.isUser) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusIcon(),
                                const SizedBox(width: 4),
                                Text(
                                  widget.message.formattedTime,
                                  style: TextStyle(
                                    color: _getTextColor(context).withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!widget.message.isUser) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message.formattedTime,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.message.hasFailed && widget.onRetry != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onRetry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, true),
          ],
        ],
      ),
    );
  }
  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser 
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser ? Colors.white : Colors.grey[600],
        size: 20,
      ),
    );
  }
  Color _getMessageColor(BuildContext context) {
    if (widget.message.isUser) {
      return Theme.of(context).primaryColor;
    } else {
      return Colors.grey[100]!;
    }
  }
  Color _getTextColor(BuildContext context) {
    if (widget.message.isUser) {
      return Colors.white;
    } else {
      return Colors.black87;
    }
  }
  Widget _buildStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red[300],
        );
    }
  }
  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.message.content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (widget.message.hasFailed && widget.onRetry != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onRetry?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Message Info'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessageInfo(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showMessageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Sender', widget.message.senderLabel),
            _buildInfoRow('Status', widget.message.status.displayName),
            _buildInfoRow('Time', widget.message.timestamp.toString()),
            _buildInfoRow('ID', widget.message.id),
            _buildInfoRow('Length', '${widget.message.content.length} characters'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}