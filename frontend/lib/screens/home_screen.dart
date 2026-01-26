import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../widgets/home/home_dashboard.dart';

/// Main home screen that displays the dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Update day streak when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().updateDayStreak();
    });
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

          return const HomeDashboard();
        },
      ),
    );
  }
}