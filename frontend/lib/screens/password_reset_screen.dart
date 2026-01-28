import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../services/form_validator.dart';
import '../theme/app_theme.dart';
import '../animations/animated_form_input.dart';
import 'login_screen.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  static const String routeName = '/password-reset';

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isEmailSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the email from route arguments if provided
    final String? initialEmail = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialEmail != null && _emailController.text.isEmpty) {
      _emailController.text = initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthenticationProvider>(
          builder: (context, authProvider, child) {
            if (_isEmailSent) {
              return _buildSuccessView();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  // Reset Form
                  _buildResetForm(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Reset Button
                  _buildResetButton(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Back to Login Link
                  _buildBackToLoginLink(),
                  
                  // Error Message
                  if (authProvider.error != null) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    _buildErrorMessage(authProvider.error!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Reset Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Title
        Text(
          'Reset Your Password',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        // Description
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm(AuthenticationProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          AnimatedFormInputConfigs.email(
            controller: _emailController,
            validator: FormValidator.validateEmail,
            onChanged: (value) {
              authProvider.updateFormField('email', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(AuthenticationProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : () => _handlePasswordReset(authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _navigateToLogin,
          child: Text(
            'Sign In',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppTheme.errorColor,
            onPressed: () {
              context.read<AuthenticationProvider>().clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
            ),
            child: const Icon(
              Icons.mark_email_read,
              size: 60,
              color: AppTheme.successColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Success Title
          Text(
            'Check Your Email',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Success Message
          Text(
            'We\'ve sent a password reset link to:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // Email Address
          Text(
            _emailController.text.trim(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Follow the instructions in the email to reset your password. The link will expire in 24 hours.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Action Buttons
          Column(
            children: [
              // Back to Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Resend Email Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEmailSent = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Resend Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Help Text
          Text(
            'Didn\'t receive the email? Check your spam folder or try again.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handlePasswordReset(AuthenticationProvider authProvider) {
    if (_formKey.currentState?.validate() ?? false) {
      authProvider.resetPassword(_emailController.text.trim()).then((_) {
        if (mounted && authProvider.error == null) {
          setState(() {
            _isEmailSent = true;
          });
        }
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }
}