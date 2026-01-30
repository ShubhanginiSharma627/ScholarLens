import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/lesson_content.dart';
import '../models/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/common/top_navigation_bar.dart';
class LessonContentScreen extends StatefulWidget {
  final LessonContent lessonContent;
  const LessonContentScreen({
    super.key,
    required this.lessonContent,
  });
  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}
class _LessonContentScreenState extends State<LessonContentScreen> {
  late AudioService _audioService;
  bool _isInitialized = false;
  @override
  void initState() {
    super.initState();
    _initializeAudioService();
  }
  void _initializeAudioService() {
    _audioService = FlutterAudioService();
    setState(() {
      _isInitialized = true;
    });
  }
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationBar(
        showBackButton: true,
      ),
      body: _isInitialized ? _buildContent() : _buildLoadingIndicator(),
    );
  }
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  Widget _buildContent() {
    return Column(
      children: [
        _buildAudioControls(),
        const Divider(),
        Expanded(
          child: _buildLessonContent(),
        ),
        _buildQuizNavigationButton(),
      ],
    );
  }
  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<AudioState>(
        stream: _audioService.audioStateStream,
        initialData: _audioService.currentState,
        builder: (context, snapshot) {
          final audioState = snapshot.data ?? AudioState.idle;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: audioState == AudioState.playing 
                    ? null 
                    : () => _playAudio(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
              ElevatedButton.icon(
                onPressed: audioState == AudioState.playing 
                    ? () => _pauseAudio() 
                    : null,
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
              ElevatedButton.icon(
                onPressed: audioState == AudioState.idle 
                    ? null 
                    : () => _stopAudio(),
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildLessonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lessonContent.lessonTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: widget.lessonContent.summaryMarkdown,
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineSmall,
              h2: Theme.of(context).textTheme.titleLarge,
              h3: Theme.of(context).textTheme.titleMedium,
              p: Theme.of(context).textTheme.bodyLarge,
              listBullet: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildQuizNavigationButton() {
    if (widget.lessonContent.quiz.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToQuiz(),
        icon: const Icon(Icons.quiz),
        label: Text('Take Quiz (${widget.lessonContent.quiz.length} questions)'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
  Future<void> _playAudio() async {
    try {
      await _audioService.speak(widget.lessonContent.audioTranscript);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _pauseAudio() async {
    try {
      await _audioService.pause();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _stopAudio() async {
    try {
      await _audioService.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _navigateToQuiz() {
    _audioService.stop();
    Navigator.of(context).pushNamed(
      '/quiz',
      arguments: widget.lessonContent.quiz,
    );
  }
}