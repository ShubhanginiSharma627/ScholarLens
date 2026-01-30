import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/flashcard_service.dart';
import '../../services/api_service.dart';
import '../../models/flashcard.dart';
import '../../utils/navigation_helper.dart';
import '../common/top_navigation_bar.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final FlashcardService _flashcardService = FlashcardService();
  final ApiService _apiService = ApiService();
  List<Flashcard> _allFlashcards = [];
  Map<String, double> _subjectProgress = {};
  UserStats? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final flashcards = await _flashcardService.getAllFlashcards();
      final subjectProgress = await _calculateSubjectProgress(flashcards);
      
      // Try to get user stats from backend
      UserStats? userStats;
      try {
        userStats = await _apiService.getUserStats();
      } catch (e) {
        // If backend fails, continue with local data only
        print('Failed to load user stats: $e');
      }
      
      setState(() {
        _allFlashcards = flashcards;
        _subjectProgress = subjectProgress;
        _userStats = userStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, double>> _calculateSubjectProgress(List<Flashcard> flashcards) async {
    final subjectGroups = <String, List<Flashcard>>{};
    
    for (final card in flashcards) {
      if (!subjectGroups.containsKey(card.subject)) {
        subjectGroups[card.subject] = [];
      }
      subjectGroups[card.subject]!.add(card);
    }
    
    final progress = <String, double>{};
    for (final entry in subjectGroups.entries) {
      final masteredCards = entry.value.where((card) => 
          card.reviewCount >= 3 && card.difficulty == Difficulty.easy).length;
      final totalCards = entry.value.length;
      progress[entry.key] = totalCards > 0 ? masteredCards / totalCards : 0.0;
    }
    
    return progress;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TopNavigationBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),
                    _buildContinueLearningSection(context),
                    const SizedBox(height: 24),
                    _buildQuickActionsSection(context),
                    const SizedBox(height: 24),
                    _buildWeakAreasSection(context),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning! 👋';
    } else if (hour < 17) {
      greeting = 'Good afternoon! 👋';
    } else {
      greeting = 'Good evening! 👋';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _allFlashcards.isEmpty 
              ? 'Ready to start your learning journey?'
              : 'Ready to continue learning?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  Widget _buildStatsGrid(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final totalCards = _allFlashcards.length;
        final masteredCards = _allFlashcards.where((card) => 
            card.reviewCount >= 3 && card.difficulty == Difficulty.easy).length;
        final dueCards = _allFlashcards.where((card) => card.isDue).length;
        
        // Use backend stats if available, otherwise fall back to local data
        final streak = _userStats?.streak ?? progress.dayStreak;
        final totalInteractions = _userStats?.totalInteractions ?? totalCards;
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              value: '$streak',
              label: 'Day Streak',
              color: Colors.orange,
              backgroundColor: Colors.orange[50]!,
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              value: '$masteredCards',
              label: 'Cards Mastered',
              color: Colors.purple,
              backgroundColor: Colors.purple[50]!,
            ),
            _buildStatCard(
              icon: Icons.quiz,
              value: '$totalInteractions',
              label: 'Total Interactions',
              color: Colors.teal,
              backgroundColor: Colors.teal[50]!,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              value: '$dueCards',
              label: 'Due Today',
              color: dueCards > 0 ? Colors.red : Colors.grey[700]!,
              backgroundColor: dueCards > 0 ? Colors.red[50]! : Colors.grey[100]!,
            ),
          ],
        );
      },
    );
  }
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildContinueLearningSection(BuildContext context) {
    if (_allFlashcards.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to ScholarLens!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first flashcard deck to start learning',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => NavigationHelper.navigateToCreateFlashcard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[600],
                  ),
                  child: const Text('Create Cards'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Find the most recently studied subject
    final recentSubject = _subjectProgress.keys.isNotEmpty 
        ? _subjectProgress.keys.first 
        : 'Study';
    final progress = _subjectProgress[recentSubject] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Continue Learning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => NavigationHelper.navigateToCards(context),
              child: Text(
                'See all',
                style: TextStyle(
                  color: Colors.purple[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[600]!, Colors.purple[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last session',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recentSubject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}% mastered',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.camera_alt,
                label: 'Snap & Solve',
                color: Colors.purple,
                onTap: () => NavigationHelper.navigateToCamera(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.upload_file,
                label: 'Upload Syllabus',
                color: Colors.teal,
                onTap: () => NavigationHelper.navigateToSyllabusScanner(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.quiz,
                label: 'Practice Quiz',
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Practice quiz coming soon!'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.layers,
                label: 'Study Cards',
                color: Colors.indigo,
                onTap: () => NavigationHelper.navigateToCards(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.chat_bubble,
                label: 'Ask Tutor',
                color: Colors.blue,
                onTap: () => NavigationHelper.navigateToTutor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_circle,
                label: 'Create Cards',
                color: Colors.green,
                onTap: () => NavigationHelper.navigateToCreateFlashcard(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildWeakAreasSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mastery by Subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (_subjectProgress.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No subjects yet.\nCreate flashcards to see your progress!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ..._subjectProgress.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSubjectProgress(
                        entry.key,
                        entry.value,
                        entry.value >= 0.7 
                            ? Colors.green 
                            : entry.value >= 0.4 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildSubjectProgress(String subject, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                icon: Icons.layers,
                iconColor: Colors.purple,
                title: 'Completed Cell Biology Deck',
                subtitle: '10 mins ago',
                hasBox: false,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.camera_alt,
                iconColor: Colors.teal,
                title: 'Solved Quadratic Equation',
                subtitle: '25 mins ago',
                hasBox: false,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.quiz,
                iconColor: Colors.orange,
                title: 'Physics Mock Test - 82%',
                subtitle: '1 hour ago',
                hasBox: false,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.menu_book,
                iconColor: Colors.teal,
                title: 'Uploaded Chemistry Textbook',
                subtitle: '3 hours ago',
                hasBox: false,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: '7-Day Streak Achieved!',
                subtitle: 'Yesterday',
                hasBox: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool hasBox,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: hasBox ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
                decoration: hasBox ? BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ) : null,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: hasBox ? Colors.blue : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}