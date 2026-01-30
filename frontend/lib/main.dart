import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'services/performance_optimizer.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PerformanceOptimizer.instance.startMonitoring();
  final deviceCapabilities = await PerformanceOptimizer.analyzeDeviceCapabilities();
  debugPrint('Device capabilities: $deviceCapabilities');
  PerformanceOptimizer.optimizeImageProcessing();
  PerformanceOptimizer.optimizeNetworkRequests();
  PerformanceOptimizer.optimizeUIRendering();
  runApp(const ScholarLensApp());
}
class ScholarLensApp extends StatelessWidget {
  const ScholarLensApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AppStateProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider.instance),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'ScholarLens',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.settings.darkModeEnabled 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home: const AuthWrapper(),
            routes: {
              LoginScreen.routeName: (context) => const LoginScreen(),
              SignupScreen.routeName: (context) => const SignupScreen(),
              PasswordResetScreen.routeName: (context) => const PasswordResetScreen(),
              '/home': (context) => const MainNavigationScreen(),
            },
          );
        },
      ),
    );
  }
}
