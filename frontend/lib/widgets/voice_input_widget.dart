import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/app_state.dart';
import '../services/voice_input_service.dart';

/// Widget that displays voice input UI with waveform animation
class VoiceInputWidget extends StatefulWidget {
  final VoiceInputService voiceInputService;
  final VoidCallback? onStartListening;
  final ValueChanged<String>? onTextReceived;
  final VoidCallback? onError;
  
  const VoiceInputWidget({
    super.key,
    required this.voiceInputService,
    this.onStartListening,
    this.onTextReceived,
    this.onError,
  });
  
  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  late Animation<double> _waveformAnimation;
  late Animation<double> _pulseAnimation;
  
  VoiceInputState _currentState = VoiceInputState.idle;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveformAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveformController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to voice input state changes
    widget.voiceInputService.voiceStateStream.listen(_onVoiceStateChanged);
    _currentState = widget.voiceInputService.currentState;
  }
  
  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onVoiceStateChanged(VoiceInputState state) {
    setState(() {
      _currentState = state;
    });
    
    switch (state) {
      case VoiceInputState.listening:
        _waveformController.repeat();
        _pulseController.repeat(reverse: true);
        break;
      case VoiceInputState.processing:
        _waveformController.stop();
        _pulseController.stop();
        break;
      case VoiceInputState.idle:
        _waveformController.stop();
        _pulseController.stop();
        break;
      case VoiceInputState.error:
        _waveformController.stop();
        _pulseController.stop();
        widget.onError?.call();
        break;
    }
  }
  
  Future<void> _startListening() async {
    try {
      widget.onStartListening?.call();
      final text = await widget.voiceInputService.startListening();
      if (text.isNotEmpty) {
        widget.onTextReceived?.call(text);
      }
    } catch (e) {
      widget.onError?.call();
    }
  }
  
  void _stopListening() {
    widget.voiceInputService.stopListening();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform visualization
        if (_currentState == VoiceInputState.listening)
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _waveformAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaveformPainter(_waveformAnimation.value),
                  size: const Size(double.infinity, 100),
                );
              },
            ),
          ),
        
        const SizedBox(height: 20),
        
        // Status text
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _getStatusColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 20),
        
        // Microphone button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _currentState == VoiceInputState.listening 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: GestureDetector(
                onTap: _currentState == VoiceInputState.listening 
                    ? _stopListening 
                    : _startListening,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getMicrophoneColor(context),
                    boxShadow: [
                      BoxShadow(
                        color: _getMicrophoneColor(context).withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getMicrophoneIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 10),
        
        // Helper text
        Text(
          _getHelperText(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  String _getStatusText() {
    switch (_currentState) {
      case VoiceInputState.idle:
        return 'Tap to speak';
      case VoiceInputState.listening:
        return 'Listening...';
      case VoiceInputState.processing:
        return 'Processing...';
      case VoiceInputState.error:
        return 'Error occurred';
    }
  }
  
  Color _getStatusColor(BuildContext context) {
    switch (_currentState) {
      case VoiceInputState.idle:
        return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
      case VoiceInputState.listening:
        return Colors.blue;
      case VoiceInputState.processing:
        return Colors.orange;
      case VoiceInputState.error:
        return Colors.red;
    }
  }
  
  Color _getMicrophoneColor(BuildContext context) {
    switch (_currentState) {
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
    switch (_currentState) {
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
  
  String _getHelperText() {
    switch (_currentState) {
      case VoiceInputState.idle:
        return 'Tap the microphone to start voice input';
      case VoiceInputState.listening:
        return 'Speak now... Tap to stop';
      case VoiceInputState.processing:
        return 'Converting speech to text...';
      case VoiceInputState.error:
        return 'Voice input failed. Try again.';
    }
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final double animationValue;
  
  WaveformPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final centerY = size.height / 2;
    final waveCount = 3;
    
    for (int i = 0; i < waveCount; i++) {
      final waveOffset = (i * size.width / waveCount);
      final amplitude = (i + 1) * 15.0; // Different amplitudes for each wave
      
      for (double x = 0; x <= size.width; x += 2) {
        final normalizedX = x / size.width;
        final wavePhase = (normalizedX * 4 * math.pi) + animationValue + (i * math.pi / 2);
        final y = centerY + math.sin(wavePhase) * amplitude * (0.5 + 0.5 * math.sin(animationValue));
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw additional animated circles for visual effect
    for (int i = 0; i < 5; i++) {
      final circleX = (i / 4) * size.width;
      final circleY = centerY + math.sin(animationValue + i) * 20;
      final radius = 3 + math.sin(animationValue * 2 + i) * 2;
      
      canvas.drawCircle(
        Offset(circleX, circleY),
        radius,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );
    }
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}