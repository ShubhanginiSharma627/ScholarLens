import 'package:flutter/material.dart';
import '../services/voice_input_service.dart';
import '../models/app_state.dart';
import '../animations/animated_interactive_element.dart';
import '../animations/animation_manager.dart';
import '../animations/animation_config.dart';

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
  late final AnimationManager _animationManager;
  late AnimationController _micAnimationController;
  late AnimationController _sendButtonController;
  late AnimationController _statusController;
  late Animation<double> _micScaleAnimation;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<Color?> _statusColorAnimation;
  
  String? _micAnimationId;
  String? _sendAnimationId;
  String? _statusAnimationId;
  
  VoiceInputState _voiceState = VoiceInputState.idle;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    _animationManager = AnimationManager();
    
    // Initialize animation controllers
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeAnimations();
    
    // Listen to text changes
    widget.controller.addListener(_onTextChanged);
    
    // Listen to voice input state changes
    widget.voiceInputService.voiceStateStream.listen(_onVoiceStateChanged);
    _voiceState = widget.voiceInputService.currentState;
  }

  void _initializeAnimations() {
    // Register animations with manager if initialized
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
    
    // Create local animations as fallback
    _createLocalAnimations();
  }

  void _registerAnimations() {
    try {
      // Register microphone animation
      final micConfig = AnimationConfigs.buttonPress.copyWith(
        scaleStart: 1.0,
        scaleEnd: 1.2,
      );
      
      _micAnimationId = _animationManager.registerController(
        controller: _micAnimationController,
        config: micConfig,
        category: AnimationCategory.microInteraction,
      );
      
      // Register send button animation
      final sendConfig = AnimationConfigs.buttonPress;
      _sendAnimationId = _animationManager.registerController(
        controller: _sendButtonController,
        config: sendConfig,
        category: AnimationCategory.microInteraction,
      );
      
      // Register status animation
      final statusConfig = AnimationConfigs.focusTransition;
      _statusAnimationId = _animationManager.registerController(
        controller: _statusController,
        config: statusConfig,
        category: AnimationCategory.feedback,
      );
      
      // Get managed animations
      final micAnim = _animationManager.getAnimation(_micAnimationId!);
      final sendAnim = _animationManager.getAnimation(_sendAnimationId!);
      final statusAnim = _animationManager.getAnimation(_statusAnimationId!);
      
      if (micAnim != null && sendAnim != null && statusAnim != null) {
        _micScaleAnimation = micAnim.animation as Animation<double>;
        _sendButtonScaleAnimation = sendAnim.animation as Animation<double>;
        // Status animation will be created locally as it needs color interpolation
        _createStatusAnimation();
      } else {
        _createLocalAnimations();
      }
    } catch (e) {
      debugPrint('Failed to register chat input animations: $e');
      _createLocalAnimations();
    }
  }

  void _createLocalAnimations() {
    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));
    
    _createStatusAnimation();
  }

  void _createStatusAnimation() {
    _statusColorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: Theme.of(context).primaryColor,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Dispose animations through manager
    if (_micAnimationId != null) {
      _animationManager.disposeController(_micAnimationId!);
    }
    if (_sendAnimationId != null) {
      _animationManager.disposeController(_sendAnimationId!);
    }
    if (_statusAnimationId != null) {
      _animationManager.disposeController(_statusAnimationId!);
    }
    
    // Dispose controllers
    _micAnimationController.dispose();
    _sendButtonController.dispose();
    _statusController.dispose();
    
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      // Animate send button state change
      if (hasText) {
        if (_statusAnimationId != null) {
          _animationManager.startAnimation(_statusAnimationId!);
        } else {
          _statusController.forward();
        }
      } else {
        _statusController.reverse();
      }
    }
  }

  void _onVoiceStateChanged(VoiceInputState state) {
    setState(() {
      _voiceState = state;
    });
    
    if (state == VoiceInputState.listening) {
      if (_micAnimationId != null) {
        _animationManager.startAnimation(_micAnimationId!);
      }
      _micAnimationController.repeat(reverse: true);
    } else {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      // Animate send button press
      if (_sendAnimationId != null) {
        _animationManager.startAnimation(_sendAnimationId!);
      } else {
        _sendButtonController.forward().then((_) {
          _sendButtonController.reverse();
        });
      }
      
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
                      child: AnimatedInteractiveElement(
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
                AnimatedBuilder(
                  animation: Listenable.merge([_sendButtonScaleAnimation, _statusColorAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _sendButtonScaleAnimation.value,
                      child: AnimatedInteractiveElement(
                        onTap: (_hasText && !widget.isLoading) ? _handleSend : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColorAnimation.value ?? Colors.grey[400],
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
                    );
                  },
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