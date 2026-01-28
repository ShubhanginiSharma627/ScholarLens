import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// Authentication wrapper that determines whether to show auth screens or main app
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check authentication status when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthenticationProvider>().checkAuthenticationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication status
        if (authProvider.isLoading && authProvider.state == AuthenticationState.unauthenticated) {
          return _LoadingScreen(
            isOfflineMode: authProvider.isOfflineMode,
          );
        }

        // Show error screen if there's a critical authentication error
        if (authProvider.state == AuthenticationState.error && 
            authProvider.lastErrorInfo?.requiresReauthentication == true) {
          return _ErrorScreen(
            errorInfo: authProvider.lastErrorInfo!,
            onRetry: () => authProvider.checkAuthenticationStatus(),
            onSignIn: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName),
          );
        }

        // Show main app if authenticated
        if (authProvider.isAuthenticated) {
          return _AuthenticatedApp(
            isOfflineMode: authProvider.isOfflineMode,
          );
        }

        // Show login screen if not authenticated
        return const LoginScreen();
      },
    );
  }
}

/// Authenticated app wrapper with offline mode indicator
class _AuthenticatedApp extends StatelessWidget {
  final bool isOfflineMode;

  const _AuthenticatedApp({
    required this.isOfflineMode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const MainNavigationScreen(),
        
        // Offline mode indicator
        if (isOfflineMode)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _OfflineModeIndicator(),
          ),
      ],
    );
  }
}

/// Offline mode indicator banner
class _OfflineModeIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.warningColor,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthenticationProvider>().checkAuthenticationStatus();
            },
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading screen shown while checking authentication status
class _LoadingScreen extends StatelessWidget {
  final bool isOfflineMode;

  const _LoadingScreen({
    this.isOfflineMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              const _AppLogo(),
              
              const SizedBox(height: 32),
              
              // Loading Indicator
              const CircularProgressIndicator(),
              
              const SizedBox(height: 16),
              
              Text(
                isOfflineMode ? 'Loading offline data...' : 'Loading Scholar Lens...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (isOfflineMode) ...[
                const SizedBox(height: 8),
                Text(
                  'You\'re currently offline',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen for critical authentication errors
class _ErrorScreen extends StatelessWidget {
  final AuthErrorInfo errorInfo;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  const _ErrorScreen({
    required this.errorInfo,
    required this.onRetry,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                
                const SizedBox(height: 24),
                
                // Error Title
                Text(
                  'Authentication Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Error Message
                Text(
                  errorInfo.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Sign In Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    if (errorInfo.isRetryable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onRetry,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Recovery Suggestions
                if (errorInfo.recoverySuggestions.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  
                  Text(
                    'Suggestions:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ...errorInfo.recoverySuggestions.take(3).map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App logo widget
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.school,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}