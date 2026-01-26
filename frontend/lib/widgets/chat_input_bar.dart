import 'package:flutter/material.dart';
import '../services/voice_input_service.dart';
import '../models/app_state.dart';

/// Widget for chat input with text field and microphone button
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoidCallback onVoiceInput;
  final bool isLoading;
  final VoiceInputService voiceInputService;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceInput,
    required this.voiceInputService,
    this.isLoading = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with TickerProviderStateMixin {
  late AnimationController _micAnimationController;
  late Animation<double> _micScaleAnimation;
  
  VoiceInputState _voiceState = VoiceInputState.idle;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to text changes
    widget.controller.addListener(_onTextChanged);
    
    // Listen to voice input state changes
    widget.voiceInputService.voiceStateStream.listen(_onVoiceStateChanged);
    _voiceState = widget.voiceInputService.currentState;
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onVoiceStateChanged(VoiceInputState state) {
    setState(() {
      _voiceState = state;
    });
    
    if (state == VoiceInputState.listening) {
      _micAnimationController.repeat(reverse: true);
    } else {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
    }
  }

  void _handleVoiceInput() {
    if (_voiceState == VoiceInputState.listening) {
      widget.voiceInputService.stopListening();
    } else {
      widget.onVoiceInput();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice input status indicator
            if (_voiceState == VoiceInputState.listening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Listening... Tap microphone to stop',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Input row
            Row(
              children: [
                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSend(),
                      enabled: !widget.isLoading && _voiceState != VoiceInputState.listening,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Microphone button
                AnimatedBuilder(
                  animation: _micScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _voiceState == VoiceInputState.listening 
                          ? _micScaleAnimation.value 
                          : 1.0,
                      child: GestureDetector(
                        onTap: widget.isLoading ? null : _handleVoiceInput,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getMicrophoneColor(),
                            boxShadow: [
                              BoxShadow(
                                color: _getMicrophoneColor().withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getMicrophoneIcon(),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Send button
                GestureDetector(
                  onTap: (_hasText && !widget.isLoading) ? _handleSend : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_hasText && !widget.isLoading)
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMicrophoneColor() {
    switch (_voiceState) {
      case VoiceInputState.idle:
        return Theme.of(context).primaryColor;
      case VoiceInputState.listening:
        return Colors.red;
      case VoiceInputState.processing:
        return Colors.orange;
      case VoiceInputState.error:
        return Colors.grey;
    }
  }

  IconData _getMicrophoneIcon() {
    switch (_voiceState) {
      case VoiceInputState.idle:
        return Icons.mic;
      case VoiceInputState.listening:
        return Icons.stop;
      case VoiceInputState.processing:
        return Icons.hourglass_empty;
      case VoiceInputState.error:
        return Icons.mic_off;
    }
  }
}