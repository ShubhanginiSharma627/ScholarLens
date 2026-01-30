import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/create_flashcard_screen.dart';
import 'screens/tutor_chat_screen.dart';
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/performance_optimizer.dart';
import 'models/models.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  PerformanceOptimizer.instance.startMonitoring();
  

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('Using default environment configuration');
  }
  
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
              '/create-flashcard': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is UploadedTextbook) {
                  String? subject = args.subject != 'Unknown' ? args.subject : null;
                  String? topic;
                  
                  if (args.keyTopics.isNotEmpty) {
                    topic = args.keyTopics.join(', ');
                  } else if (subject != null) {
                    topic = subject;
                  } else {
                    topic = args.title;
                  }
                  
                  return CreateFlashcardScreen(
                    initialSubject: subject ?? args.title,
                    initialCategory: args.title,
                    initialTopic: topic,
                  );
                }
                return const CreateFlashcardScreen();
              },
              '/tutor-chat': (context) {
                return const TutorChatScreen();
              },
              '/quiz': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is UploadedTextbook) {
                  return Scaffold(
                    appBar: AppBar(
                      title: Text('Quiz - ${args.title}'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    body: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quiz feature coming soon!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'We\'re working on interactive quizzes for your textbooks.',
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
                return const Scaffold(
                  body: Center(child: Text('Quiz feature coming soon!')),
                );
              },
              '/lesson-content': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is Map<String, dynamic>) {
                  final textbook = args['textbook'] as UploadedTextbook?;
                  final chapter = args['chapter'] as int?;
                  
                  if (textbook != null && chapter != null) {
                    return Scaffold(
                      appBar: AppBar(
                        title: Text('${textbook.title} - Chapter $chapter'),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      body: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Lesson content coming soon!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'We\'re building interactive lesson content for your textbooks.',
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
                return const Scaffold(
                  body: Center(child: Text('Invalid lesson content arguments')),
                );
              },
            },
          );
        },
      ),
    );
  }
}
