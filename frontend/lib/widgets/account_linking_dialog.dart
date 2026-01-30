import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
class AccountLinkingDialog extends StatefulWidget {
  final String conflictEmail;
  final String conflictProvider;
  const AccountLinkingDialog({
    super.key,
    required this.conflictEmail,
    required this.conflictProvider,
  });
  @override
  State<AccountLinkingDialog> createState() => _AccountLinkingDialogState();
}
class _AccountLinkingDialogState extends State<AccountLinkingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  @override
  void initState() {
    super.initState();
    _emailController.text = widget.conflictEmail;
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'An account with ${widget.conflictEmail} already exists using ${widget.conflictProvider} sign-in.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'To merge your accounts, please enter your ${widget.conflictProvider} password:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMergeForm(authProvider),
                const SizedBox(height: AppTheme.spacingM),
                _buildRememberMe(),
                if (authProvider.error != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  _buildErrorMessage(authProvider.error!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: authProvider.isLoading ? null : () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _handleMerge(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Merge Accounts'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildMergeForm(AuthenticationProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: '${widget.conflictProvider} Password',
              hintText: 'Enter your ${widget.conflictProvider} password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleMerge(authProvider),
          ),
        ],
      ),
    );
  }
  Widget _buildRememberMe() {
    return CheckboxListTile(
      value: _rememberMe,
      onChanged: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
      title: Text(
        'Remember me',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _handleMerge(AuthenticationProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      authProvider.clearError();
      await authProvider.mergeGoogleAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (authProvider.isAuthenticated && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
Future<bool?> showAccountLinkingDialog(
  BuildContext context, {
  required String conflictEmail,
  required String conflictProvider,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AccountLinkingDialog(
      conflictEmail: conflictEmail,
      conflictProvider: conflictProvider,
    ),
  );
}