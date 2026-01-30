import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../common/loading_animations.dart';
class CircularProgressCard extends StatelessWidget {
  final String subject;
  final double progress;
  final VoidCallback onTap;
  final bool isLoading;
  const CircularProgressCard({
    super.key,
    required this.subject,
    required this.progress,
    required this.onTap,
    this.isLoading = false,
  });
  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    final subjectColor = _getSubjectColor(subject);
    return LoadingAnimations.scaleIn(
      child: SizedBox(
        width: 110,
        child: Card(
          elevation: AppTheme.elevationS,
          margin: const EdgeInsets.all(AppTheme.spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    LoadingAnimations.circularLoader(
                      size: 50,
                      color: subjectColor,
                    )
                  else
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subjectColor.withValues(alpha: 0.1),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(60, 60),
                            painter: CircularProgressPainter(
                              progress: progress,
                              color: subjectColor,
                              strokeWidth: 5,
                            ),
                          ),
                          Center(
                            child: Text(
                              '$percentage%',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    _getDisplayName(subject),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return AppTheme.primaryColor;
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return AppTheme.successColor;
      case 'history':
        return const Color(0xFF8B5A2B);
      case 'english':
      case 'literature':
        return const Color(0xFF7C3AED);
      case 'geography':
        return const Color(0xFF0891B2);
      case 'computer science':
      case 'programming':
        return AppTheme.accentColor;
      default:
        return AppTheme.secondaryColor;
    }
  }
  String _getDisplayName(String subject) {
    if (subject.length <= 10) {
      return subject[0].toUpperCase() + subject.substring(1).toLowerCase();
    }
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return 'Math';
      case 'computer science':
        return 'CS';
      case 'literature':
        return 'Lit';
      default:
        return subject.length > 8 
            ? '${subject.substring(0, 8)}...'
            : subject[0].toUpperCase() + subject.substring(1).toLowerCase();
    }
  }
}
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }
  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}