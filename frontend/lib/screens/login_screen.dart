import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/form_validator.dart';
import '../theme/app_theme.dart';
import '../widgets/common/loading_animations.dart';
import '../animations/animated_form_input.dart';
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
      body: SafeArea(
        child: Consumer<AuthenticationProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  // Login Form
                  _buildLoginForm(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Remember Me & Forgot Password
                  _buildRememberMeAndForgotPassword(),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Login Button
                  _buildLoginButton(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Divider
                  _buildDivider(),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Google Sign-In Button
                  _buildGoogleSignInButton(authProvider),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Sign Up Link
                  _buildSignUpLink(),
                  
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

  Widget _buildLoginForm(AuthenticationProvider authProvider) {
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
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Password Field
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

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      children: [
        // Remember Me Checkbox
        Expanded(
          child: CheckboxListTile(
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
          ),
        ),
        
        // Forgot Password Link
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthenticationProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : () => _handleLogin(authProvider),
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
                'Sign In',
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

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _navigateToSignUp,
          child: Text(
            'Sign Up',
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

  void _handleLogin(AuthenticationProvider authProvider) {
    if (_formKey.currentState?.validate() ?? false) {
      authProvider.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
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