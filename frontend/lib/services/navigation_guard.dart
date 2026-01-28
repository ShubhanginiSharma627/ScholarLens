import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/authentication_provider.dart';
import '../screens/login_screen.dart';

/// Navigation guard service for protecting authenticated routes
class NavigationGuard {
  static NavigationGuard? _instance;
  static NavigationGuard get instance => _instance ??= NavigationGuard._();

  NavigationGuard._();

  /// Check if user is authenticated and redirect to login if not
  static bool requiresAuthentication(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    
    if (!authProvider.isAuthenticated) {
      // Redirect to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
      return false;
    }
    
    return true;
  }

  /// Check if user is authenticated without redirecting
  static bool isAuthenticated(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    return authProvider.isAuthenticated;
  }

  /// Check if user has specific role/permission (for future use)
  static bool hasPermission(BuildContext context, String permission) {
    final authProvider = context.read<AuthenticationProvider>();
    
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return false;
    }

    // For now, all authenticated users have all permissions
    // This can be extended in the future with role-based access control
    return true;
  }

  /// Wrapper widget that protects child routes
  static Widget protectedRoute({
    required Widget child,
    String? requiredPermission,
    Widget? fallback,
  }) {
    return Builder(
      builder: (context) {
        final authProvider = context.watch<AuthenticationProvider>();
        
        // Show loading if authentication is being checked
        if (authProvider.isLoading && 
            authProvider.state == AuthenticationState.unauthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check authentication
        if (!authProvider.isAuthenticated) {
          return fallback ?? const LoginScreen();
        }

        // Check permission if required
        if (requiredPermission != null && 
            !hasPermission(context, requiredPermission)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You don\'t have permission to access this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }

  /// Route generator with authentication checks
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => protectedRoute(
            child: const _HomeScreen(), // Replace with your home screen
          ),
        );
      
      case '/profile':
        return MaterialPageRoute(
          builder: (context) => protectedRoute(
            child: const _ProfileScreen(), // Replace with your profile screen
          ),
        );
      
      case '/settings':
        return MaterialPageRoute(
          builder: (context) => protectedRoute(
            child: const _SettingsScreen(), // Replace with your settings screen
            requiredPermission: 'admin', // Example permission
          ),
        );
      
      default:
        return null;
    }
  }

  /// Check authentication status and handle session expiry
  static Future<bool> checkAuthenticationStatus(BuildContext context) async {
    final authProvider = context.read<AuthenticationProvider>();
    
    try {
      await authProvider.checkAuthenticationStatus();
      return authProvider.isAuthenticated;
    } catch (e) {
      debugPrint('Authentication status check failed: $e');
      return false;
    }
  }

  /// Handle authentication state changes
  static void handleAuthenticationStateChange(
    BuildContext context,
    AuthenticationState state,
  ) {
    switch (state) {
      case AuthenticationState.unauthenticated:
        // Redirect to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
          (route) => false,
        );
        break;
      
      case AuthenticationState.authenticated:
        // User is authenticated, no action needed
        break;
      
      case AuthenticationState.error:
        // Handle authentication error
        final authProvider = context.read<AuthenticationProvider>();
        if (authProvider.errorType?.requiresReauthentication == true) {
          // Force re-authentication
          Navigator.of(context).pushNamedAndRemoveUntil(
            LoginScreen.routeName,
            (route) => false,
          );
        }
        break;
      
      case AuthenticationState.authenticating:
        // Show loading state, no action needed
        break;
    }
  }

  /// Middleware for route protection
  static Widget routeMiddleware({
    required Widget child,
    bool requiresAuth = true,
    String? requiredPermission,
    VoidCallback? onAuthRequired,
  }) {
    return Builder(
      builder: (context) {
        if (!requiresAuth) {
          return child;
        }

        return Consumer<AuthenticationProvider>(
          builder: (context, authProvider, _) {
            // Handle authentication state changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              handleAuthenticationStateChange(context, authProvider.state);
            });

            // Show loading during authentication check
            if (authProvider.isLoading && 
                authProvider.state == AuthenticationState.unauthenticated) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Check authentication
            if (!authProvider.isAuthenticated) {
              onAuthRequired?.call();
              return const LoginScreen();
            }

            // Check permission
            if (requiredPermission != null && 
                !hasPermission(context, requiredPermission)) {
              return const _AccessDeniedScreen();
            }

            return child;
          },
        );
      },
    );
  }
}

/// Access denied screen
class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You don\'t have permission to access this page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens - replace with actual screens
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}