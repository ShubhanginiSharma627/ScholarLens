import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../widgets/common/top_navigation_bar.dart';
import 'create_flashcard_screen.dart';
import 'all_cards_view_screen.dart';
class FlashcardManagementScreen extends StatefulWidget {
  const FlashcardManagementScreen({super.key});
  @override
  State<FlashcardManagementScreen> createState() => _FlashcardManagementScreenState();
}
class _FlashcardManagementScreenState extends State<FlashcardManagementScreen> {
  final _flashcardService = FlashcardService();
  List<Flashcard> _allFlashcards = [];
  List<String> _subjects = [];
  bool _isLoading = true;
  final List<Map<String, dynamic>> _mockDecks = [
    {
      'name': 'Cell Biology',
      'count': 24,
      'color': Colors.purple,
      'icon': Icons.layers,
    },
    {
      'name': 'Physics Mechanics',
      'count': 18,
      'color': Colors.teal,
      'icon': Icons.layers,
    },
    {
      'name': 'Algebra Basics',
      'count': 32,
      'color': Colors.orange,
      'icon': Icons.layers,
    },
    {
      'name': 'Organic Chemistry',
      'count': 15,
      'color': Colors.blue,
      'icon': Icons.layers,
    },
  ];
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final flashcards = await _flashcardService.getAllFlashcards();
      final subjects = await _flashcardService.getSubjects();
      setState(() {
        _allFlashcards = flashcards;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading flashcards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TopNavigationBar(
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Flashcards',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-generated cards for efficient learning',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Decks',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (context) => const CreateFlashcardScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                  }
                                },
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Generate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ..._mockDecks.map((deck) => _buildDeckTile(deck)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[600]!, Colors.orange[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Flashcards are stored locally using Gemini Nano, so you can study even without internet!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  Widget _buildDeckTile(Map<String, dynamic> deck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (deck['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            deck['icon'] as IconData,
            color: deck['color'] as Color,
            size: 24,
          ),
        ),
        title: Text(
          deck['name'] as String,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${deck['count']} cards',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AllCardsViewScreen(
                      subject: deck['name'] as String,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.list_rounded, size: 16),
              label: const Text('All Cards'),
              style: TextButton.styleFrom(
                foregroundColor: deck['color'] as Color,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.play_arrow_rounded,
          color: deck['color'] as Color,
          size: 28,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${deck['name']} deck...'),
            ),
          );
        },
      ),
    );
  }
}