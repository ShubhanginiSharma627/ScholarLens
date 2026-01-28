import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/form_validator.dart';
import '../theme/app_theme.dart';
import '../animations/animated_form_input.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthenticationProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Signup Form
                  _buildSignupForm(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Terms and Conditions
                  _buildTermsAndConditions(),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Remember Me
                  _buildRememberMe(),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Signup Button
                  _buildSignupButton(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Divider
                  _buildDivider(),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Google Sign-In Button
                  _buildGoogleSignInButton(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Login Link
                  _buildLoginLink(),
                  
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
        // App Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: const Icon(
            Icons.school,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Welcome Text
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Join Scholar Lens and start your learning journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupForm(AuthenticationProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Field
          AnimatedFormInput(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: FormValidator.validateName,
            onChanged: (value) {
              authProvider.updateFormField('name', value);
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Email Field
          AnimatedFormInputConfigs.email(
            controller: _emailController,
            validator: FormValidator.validateEmail,
            onChanged: (value) {
              authProvider.updateFormField('email', value);
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Password Field
          Consumer<AuthenticationProvider>(
            builder: (context, provider, child) {
              final passwordResult = provider.formValidationState.getFieldResult('password');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedFormInputConfigs.password(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
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
                    validator: FormValidator.validatePassword,
                    onChanged: (value) {
                      authProvider.updateFormField('password', value);
                      // Update confirm password validation
                      if (_confirmPasswordController.text.isNotEmpty) {
                        authProvider.updateFormField('confirmPassword', _confirmPasswordController.text);
                      }
                    },
                  ),
                  
                  // Password Strength Indicator
                  if (passwordResult != null && passwordResult.metadata != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    _buildPasswordStrengthIndicator(
                      passwordResult.metadata!['strength'] as int,
                      passwordResult.metadata!['strengthDescription'] as String,
                    ),
                  ],
                ],
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Confirm Password Field
          AnimatedFormInput(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) => FormValidator.validateConfirmPassword(
              _passwordController.text,
              value,
            ),
            onChanged: (value) {
              authProvider.updateFormField('confirmPassword', value);
            },
            onFieldSubmitted: (_) => _handleSignup(authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(int strength, String description) {
    Color strengthColor;
    switch (strength) {
      case 0:
      case 1:
        strengthColor = AppTheme.errorColor;
        break;
      case 2:
        strengthColor = AppTheme.warningColor;
        break;
      case 3:
        strengthColor = AppTheme.accentColor;
        break;
      case 4:
        strengthColor = AppTheme.successColor;
        break;
      default:
        strengthColor = AppTheme.secondaryTextColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 4,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return CheckboxListTile(
      value: _acceptTerms,
      onChanged: (value) {
        setState(() {
          _acceptTerms = value ?? false;
        });
      },
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
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

  Widget _buildSignupButton(AuthenticationProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading || !_acceptTerms
            ? null
            : () => _handleSignup(authProvider),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton(AuthenticationProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : () => _handleGoogleSignIn(authProvider),
        icon: Image.asset(
          'assets/images/google_logo.png', // You'll need to add this asset
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.g_mobiledata,
              size: 24,
              color: AppTheme.primaryColor,
            );
          },
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primaryColor),
          foregroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
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

  void _handleSignup(AuthenticationProvider authProvider) {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions to continue'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      authProvider.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        rememberMe: _rememberMe,
      );
    }
  }

  void _handleGoogleSignIn(AuthenticationProvider authProvider) {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions to continue'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    authProvider.signUpWithGoogle(rememberMe: _rememberMe);
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }
}