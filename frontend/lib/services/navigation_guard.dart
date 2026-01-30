import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/authentication_provider.dart';
import '../screens/login_screen.dart';
class NavigationGuard {
  static NavigationGuard? _instance;
  static NavigationGuard get instance => _instance ??= NavigationGuard._();
  NavigationGuard._();
  static bool requiresAuthentication(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
      return false;
    }
    return true;
  }
  static bool isAuthenticated(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    return authProvider.isAuthenticated;
  }
  static bool hasPermission(BuildContext context, String permission) {
    final authProvider = context.read<AuthenticationProvider>();
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return false;
    }
    return true;
  }
  static Widget protectedRoute({
    required Widget child,
    String? requiredPermission,
    Widget? fallback,
  }) {
    return Builder(
      builder: (context) {
        final authProvider = context.watch<AuthenticationProvider>();
        if (authProvider.isLoading && 
            authProvider.state == AuthenticationState.unauthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!authProvider.isAuthenticated) {
          return fallback ?? const LoginScreen();
        }
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
  static void handleAuthenticationStateChange(
    BuildContext context,
    AuthenticationState state,
  ) {
    switch (state) {
      case AuthenticationState.unauthenticated:
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
          (route) => false,
        );
        break;
      case AuthenticationState.authenticated:
        break;
      case AuthenticationState.error:
        final authProvider = context.read<AuthenticationProvider>();
        if (authProvider.errorType?.requiresReauthentication == true) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            LoginScreen.routeName,
            (route) => false,
          );
        }
        break;
      case AuthenticationState.authenticating:
        break;
    }
  }
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              handleAuthenticationStateChange(context, authProvider.state);
            });
            if (authProvider.isLoading && 
                authProvider.state == AuthenticationState.unauthenticated) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!authProvider.isAuthenticated) {
              onAuthRequired?.call();
              return const LoginScreen();
            }
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