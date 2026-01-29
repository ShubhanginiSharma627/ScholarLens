import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../services/form_validator.dart';
import '../theme/app_theme.dart';

import '../widgets/common/modern_form_card.dart';
import '../widgets/common/form_divider.dart';
import '../widgets/common/modern_text_field.dart';
import '../widgets/common/modern_button.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  // Form Card
                  ModernFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sign In Header
                        _buildFormHeader(),
                        
                        const SizedBox(height: AppTheme.spacingXL),
                        
                        // Google Sign-In Button
                        _buildGoogleSignInButton(authProvider),
                        
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Divider
                        const FormDivider(),
                        
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Login Form
                        _buildLoginForm(authProvider),
                        
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Forgot Password Link
                        _buildForgotPasswordLink(),
                        
                        const SizedBox(height: AppTheme.spacingM),
                        
                        // Remember Me
                        _buildRememberMe(),
                        
                        const SizedBox(height: AppTheme.spacingXL),
                        
                        // Login Button
                        _buildLoginButton(authProvider),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Sign Up Link
                  _buildSignUpLink(),
                  
                  // Terms Text
                  const SizedBox(height: AppTheme.spacingL),
                  _buildTermsText(),
                  
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
          'Welcome Back',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Sign in to continue your learning journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.secondaryTextColor,
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
          'Sign In',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Enter your credentials to access your account',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthenticationProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
          ModernTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Forgot password?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          'Remember me for 30 days',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthenticationProvider authProvider) {
    return ModernButton.primary(
      text: 'Sign In',
      isLoading: authProvider.isLoading,
      onPressed: () => _handleLogin(authProvider),
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

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.secondaryTextColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: _navigateToSignUp,
          child: Text(
            'Sign up',
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

  void _handleLogin(AuthenticationProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      await authProvider.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      
      // No manual navigation needed - AuthWrapper handles this automatically
    }
  }

  void _handleGoogleSignIn(AuthenticationProvider authProvider) {
    authProvider.signInWithGoogle(rememberMe: _rememberMe);
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    
    Navigator.of(context).pushNamed(
      PasswordResetScreen.routeName,
      arguments: email.isNotEmpty ? email : null,
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacementNamed(SignupScreen.routeName);
  }
}