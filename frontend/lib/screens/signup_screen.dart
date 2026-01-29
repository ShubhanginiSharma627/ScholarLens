import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../services/form_validator.dart';
import '../theme/app_theme.dart';
import '../animations/animated_form_input.dart';
import '../widgets/common/modern_form_card.dart';
import '../widgets/common/form_divider.dart';
import '../widgets/common/modern_text_field.dart';
import '../widgets/common/modern_button.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthenticationProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Form Card
                  ModernFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sign Up Header
                        _buildFormHeader(),
                        
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Google Sign-In Button
                        _buildGoogleSignInButton(authProvider),
                        
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Divider
                        const FormDivider(),
                        
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Signup Form
                        _buildSignupForm(authProvider),
                        
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Terms and Conditions
                        _buildTermsAndConditions(),
                        
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Signup Button
                        _buildSignupButton(authProvider),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: const Icon(
            Icons.school,
            size: 32,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Welcome Text
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXS),
        
        Text(
          'Start your learning journey today',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryTextColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormHeader() {
    return Column(
      children: [
        Text(
          'Sign Up',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryTextColor,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXS),
        
        Text(
          'Create your account to get started',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.secondaryTextColor,
            fontSize: 13,
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
          ModernTextField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: Icons.person_outlined,
            textCapitalization: TextCapitalization.words,
            validator: FormValidator.validateName,
            onChanged: (value) {
              authProvider.updateFormField('name', value);
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Email Field
          ModernTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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
                  ModernTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.secondaryTextColor,
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
                  
                  const SizedBox(height: AppTheme.spacingS),
                  
                  // Password requirement text
                  Text(
                    'Must be at least 6 characters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
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
          ModernTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: '••••••••',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.secondaryTextColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: RichText(
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
        ),
      ],
    );
  }

  Widget _buildSignupButton(AuthenticationProvider authProvider) {
    return ModernButton.primary(
      text: 'Create Account',
      isLoading: authProvider.isLoading,
      onPressed: _acceptTerms ? () => _handleSignup(authProvider) : null,
    );
  }

  Widget _buildGoogleSignInButton(AuthenticationProvider authProvider) {
    return ModernButton.secondary(
      text: 'Continue with Google',
      isLoading: authProvider.isLoading,
      icon: Image.asset(
        'assets/images/google_logo.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.g_mobiledata,
            size: 20,
            color: AppTheme.primaryColor,
          );
        },
      ),
      onPressed: () => _handleGoogleSignIn(authProvider),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: _navigateToLogin,
          child: Text(
            'Sign in',
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

  void _handleSignup(AuthenticationProvider authProvider) async {
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
      await authProvider.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        rememberMe: _rememberMe,
      );
      
      // No manual navigation needed - AuthWrapper handles this automatically
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