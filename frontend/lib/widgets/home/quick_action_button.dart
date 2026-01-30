import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../common/loading_animations.dart';
class QuickActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const QuickActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color,
    required this.onTap,
  });
  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}
class _QuickActionButtonState extends State<QuickActionButton> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppTheme.primaryColor;
    return LoadingAnimations.scaleIn(
      delay: const Duration(milliseconds: 100),
      child: Card(
        elevation: AppTheme.elevationS,
        margin: const EdgeInsets.all(AppTheme.spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: LoadingAnimations.bouncingButton(
          onPressed: _isLoading ? () {} : _handleTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: buttonColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: _isLoading
                            ? LoadingAnimations.circularLoader(
                                size: 20,
                                color: buttonColor,
                              )
                            : Icon(
                                widget.icon,
                                color: buttonColor,
                                size: 20,
                              ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: buttonColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Flexible(
                    child: Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _handleTap() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      widget.onTap();
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}