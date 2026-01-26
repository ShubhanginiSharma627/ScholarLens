import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_question.dart';
import '../models/learning_session.dart';
import '../models/lesson_content.dart';
import '../services/progress_service.dart';
import '../providers/progress_provider.dart';
import '../widgets/common/top_navigation_bar.dart';

/// Screen for displaying interactive quiz questions with multiple choice options
class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final LessonContent lessonContent;
  final String subject;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.lessonContent,
    this.subject = 'General',
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;
  final List<int> _userAnswers = [];
  final List<bool> _correctAnswers = [];
  late DateTime _quizStartTime;
  late ProgressService _progressService;

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _progressService = ProgressService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationBar(
        showBackButton: true,
      ),
      body: _buildQuizContent(),
    );
  }

  Widget _buildQuizContent() {
    if (_currentQuestionIndex >= widget.questions.length) {
      return _buildQuizComplete();
    }

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        // Question content
        Expanded(
          child: _buildQuestionContent(),
        ),
        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = widget.questions[_currentQuestionIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Answer options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return _buildAnswerOption(index, option, question);
          }),
          // Feedback section
          if (_showFeedback) _buildFeedback(question),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int index, String option, QuizQuestion question) {
    Color? backgroundColor;
    Color? textColor;
    IconData? icon;

    if (_showFeedback) {
      if (index == question.correctIndex) {
        backgroundColor = Colors.green[100];
        textColor = Colors.green[800];
        icon = Icons.check_circle;
      } else if (index == _selectedAnswerIndex && !_isAnswerCorrect) {
        backgroundColor = Colors.red[100];
        textColor = Colors.red[800];
        icon = Icons.cancel;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: backgroundColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _selectedAnswerIndex == index 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
            child: Text(
              String.fromCharCode(65 + index), // A, B, C, D
              style: TextStyle(
                color: _selectedAnswerIndex == index 
                    ? Colors.white 
                    : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            option,
            style: TextStyle(
              color: textColor,
              fontWeight: _selectedAnswerIndex == index 
                  ? FontWeight.w500 
                  : FontWeight.normal,
            ),
          ),
          trailing: _showFeedback ? Icon(icon, color: textColor) : null,
          onTap: _showFeedback ? null : () => _selectAnswer(index),
          selected: _selectedAnswerIndex == index,
        ),
      ),
    );
  }

  Widget _buildFeedback(QuizQuestion question) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: Card(
        color: _isAnswerCorrect ? Colors.green[50] : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isAnswerCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAnswerCorrect ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isAnswerCorrect ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question.explanation,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton(
            onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
            child: const Text('Previous'),
          ),
          // Next/Submit button
          ElevatedButton(
            onPressed: _selectedAnswerIndex != null ? _nextQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _currentQuestionIndex == widget.questions.length - 1 
                  ? 'Finish Quiz' 
                  : (_showFeedback ? 'Next Question' : 'Submit Answer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizComplete() {
    final correctCount = _correctAnswers.where((correct) => correct).length;
    final totalQuestions = widget.questions.length;
    final accuracy = correctCount / totalQuestions;
    final accuracyPercentage = (accuracy * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Quiz Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Your Score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correctCount / $totalQuestions',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$accuracyPercentage% Accuracy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finishQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Continue Learning',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  void _nextQuestion() {
    if (!_showFeedback && _selectedAnswerIndex != null) {
      // Show feedback first
      final question = widget.questions[_currentQuestionIndex];
      _isAnswerCorrect = question.isCorrectAnswer(_selectedAnswerIndex!);
      
      _userAnswers.add(_selectedAnswerIndex!);
      _correctAnswers.add(_isAnswerCorrect);
      
      setState(() {
        _showFeedback = true;
      });
    } else if (_showFeedback) {
      // Move to next question
      if (_currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = null;
          _showFeedback = false;
          _isAnswerCorrect = false;
        });
      } else {
        // Quiz complete
        setState(() {
          _currentQuestionIndex++;
        });
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerIndex = _userAnswers.isNotEmpty 
            ? _userAnswers[_currentQuestionIndex] 
            : null;
        _showFeedback = false;
        _isAnswerCorrect = false;
      });
    }
  }

  Future<void> _finishQuiz() async {
    try {
      // Create learning session
      final session = LearningSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: widget.subject,
        topic: widget.lessonContent.lessonTitle,
        startTime: _quizStartTime,
        endTime: DateTime.now(),
        questionsAnswered: widget.questions.length,
        correctAnswers: _correctAnswers.where((correct) => correct).length,
        content: widget.lessonContent,
      );

      // Update progress
      await _progressService.updateLearningStats(session);
      await _progressService.updateDayStreak();

      // Update progress provider
      if (mounted) {
        final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
        await progressProvider.updateWithSession(session);
      }

      // Navigate back to home or lesson content
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}