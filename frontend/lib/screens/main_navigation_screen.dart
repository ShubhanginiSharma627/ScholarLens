import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../services/app_lifecycle_manager.dart';
import '../services/performance_optimizer.dart';
import '../widgets/home/home_dashboard.dart';
import '../widgets/navigation/animated_bottom_navigation.dart';
import '../widgets/navigation/enhanced_speed_dial.dart';
import 'tutor_chat_screen.dart';
import 'flashcard_management_screen.dart';
import 'analytics_screen.dart';
import 'snap_and_solve_screen.dart';
import 'syllabus_scanner_screen.dart';

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver, AppLifecycleMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  AppLifecycleManager? _lifecycleManager;

  // List of navigation screens (excluding center button)
  final List<Widget> _screens = const [
    _HomeTab(),           // Index 0 -> Tab 0 (Home)
    TutorChatScreen(),    // Index 1 -> Tab 1 (Tutor)  
    FlashcardManagementScreen(), // Index 2 -> Tab 3 (Cards)
    AnalyticsScreen(),    // Index 3 -> Tab 4 (Analytics)
  ];

  // Navigation tab information
  final List<NavigationTab> _tabs = const [
    NavigationTab(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Home',
    ),
    NavigationTab(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Tutor',
    ),
    NavigationTab(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: '',
      isCenter: true,
    ),
    NavigationTab(
      icon: Icons.layers_outlined,
      activeIcon: Icons.layers,
      label: 'Cards',
    ),
    NavigationTab(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Add frame time monitoring
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startFrameTimeMonitoring();
    });
    
    // Update day streak when app loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().updateDayStreak();
      _restoreNavigationState();
    });
  }

  /// Starts monitoring frame rendering times
  void _startFrameTimeMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      final frameTime = timeStamp.inMicroseconds;
      PerformanceOptimizer.instance.recordFrameTime(frameTime);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  AppLifecycleManager createLifecycleManager() {
    return AppLifecycleManager(
      audioService: context.read<AppStateProvider>().audioService,
      onStateRestored: _restoreNavigationState,
    );
  }

  @override
  void onAppPaused() {
    super.onAppPaused();
    _saveNavigationState();
  }

  @override
  void onAppResumed() {
    super.onAppResumed();
    _restoreNavigationState();
  }

  @override
  void onAppDetached() {
    super.onAppDetached();
    _saveNavigationState();
  }

  void _saveNavigationState() {
    // Save current tab index and additional state for restoration
    _lifecycleManager?.saveNavigationState(_currentIndex, additionalData: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _restoreNavigationState() async {
    // Restore saved tab index and state
    final navigationState = await _lifecycleManager?.getNavigationState();
    if (navigationState != null) {
      final savedIndex = navigationState['currentIndex'] as int?;
      if (savedIndex != null && 
          savedIndex != _currentIndex && 
          savedIndex >= 0 && 
          savedIndex < _screens.length) {
        setState(() {
          _currentIndex = savedIndex;
        });
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  void _onTabTapped(int index) {
    // Handle center button (speed dial) differently
    if (index == 2) {
      _showSpeedDial(context);
      return;
    }

    // Map tab index to screen index
    int screenIndex;
    if (index < 2) {
      // Home (0) and Tutor (1) map directly
      screenIndex = index;
    } else {
      // Cards (3) and Analytics (4) map to screen indices 2 and 3
      screenIndex = index - 1;
    }
    
    if (screenIndex == _currentIndex) return;

    // Stop audio when navigating away from current tab
    final audioService = context.read<AppStateProvider>().audioService;
    if (audioService != null) {
      audioService.stop();
    }

    setState(() {
      _currentIndex = screenIndex;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      screenIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSpeedDial(BuildContext context) {
    showEnhancedSpeedDial(
      context,
      actions: [
        SpeedDialAction(
          icon: Icons.camera_alt,
          label: 'Snap & Solve',
          backgroundColor: const Color(0xFF7C3AED), // Purple
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SnapAndSolveScreen(),
              ),
            );
          },
        ),
        SpeedDialAction(
          icon: Icons.menu_book,
          label: 'Scan Syllabus',
          backgroundColor: const Color(0xFF14B8A6), // Teal
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SyllabusScannerScreen(),
              ),
            );
          },
        ),
      ],
      backdropColor: Colors.black.withValues(alpha: 0.2),
      blurSigma: 15.0,
    );
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<AppStateProvider, ProgressProvider, ChatProvider>(
        builder: (context, appState, progress, chat, child) {
          if (appState.isLoading || progress.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _screens,
          );
        },
      ),
      bottomNavigationBar: AnimatedBottomNavigation(
        tabs: _tabs,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// Home tab wrapper to handle home-specific initialization
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    // Update day streak when home tab loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProgressProvider>().updateDayStreak();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeDashboard();
  }
}