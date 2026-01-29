import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A divider widget for authentication forms
/// Shows "OR CONTINUE WITH" text between different authentication methods
class FormDivider extends StatelessWidget {
  final String text;

  const FormDivider({
    super.key,
    this.text = 'OR CONTINUE WITH',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppTheme.borderColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppTheme.borderColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}