import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/common/polished_components.dart';
class TextbookDetailScreen extends StatefulWidget {
  final UploadedTextbook textbook;
  const TextbookDetailScreen({
    super.key,
    required this.textbook,
  });
  @override
  State<TextbookDetailScreen> createState() => _TextbookDetailScreenState();
}
class _TextbookDetailScreenState extends State<TextbookDetailScreen> {
  late TextbookProgress progress;
  @override
  void initState() {
    super.initState();
    _loadTextbookProgress();
  }
  void _loadTextbookProgress() {
    final totalChapters = widget.textbook.chapters.isNotEmpty 
        ? widget.textbook.chapters.length 
        : 1;
    
    final hasRealChapters = widget.textbook.chapters.isNotEmpty;
    final completedChapters = hasRealChapters ? (totalChapters * 0.3).round() : 0;
    final currentChapter = hasRealChapters ? (completedChapters + 1).clamp(1, totalChapters) : 1;
    
    setState(() {
      progress = TextbookProgress(
        textbookId: widget.textbook.id,
        completedChapters: completedChapters,
        totalChapters: totalChapters,
        studyHours: hasRealChapters ? 4.5 : 0.5,
        currentChapter: currentChapter,
        keyTopics: widget.textbook.keyTopics.isNotEmpty 
            ? widget.textbook.keyTopics 
            : ['Document Analysis', 'Key Concepts', 'Study Materials'],
        chapterProgresses: _generateChapterProgresses(),
        lastStudied: DateTime.now().subtract(const Duration(hours: 2)),
      );
    });
  }
  List<ChapterProgress> _generateChapterProgresses() {
    if (widget.textbook.chapters.isEmpty) {
      return [
        ChapterProgress(
          chapterNumber: 1,
          chapterTitle: 'Document Analysis',
          pageRange: 'Full Document',
          estimatedReadingTimeMinutes: 45,
          isCompleted: false,
          progressPercentage: 0.0,
          completedAt: null,
          lastAccessed: null,
        ),
      ];
    }
    
    return widget.textbook.chapters.asMap().entries.map((entry) {
      final index = entry.key;
      final chapter = entry.value;
      final chapterNumber = index + 1;
      final totalChapters = widget.textbook.chapters.length;
      
      final completedCount = (totalChapters * 0.3).round();
      final isCompleted = index < completedCount;
      final isCurrent = index == completedCount;
      
      return ChapterProgress(
        chapterNumber: chapterNumber,
        chapterTitle: chapter,
        pageRange: widget.textbook.totalPages > 0 
            ? 'Pages ${((index * widget.textbook.totalPages) / totalChapters).round() + 1}-${(((index + 1) * widget.textbook.totalPages) / totalChapters).round()}'
            : 'Pages ${(index * 30) + 1}-${(index + 1) * 30}',
        estimatedReadingTimeMinutes: 45 + (index * 5),
        isCompleted: isCompleted,
        progressPercentage: isCompleted ? 100.0 : (isCurrent ? 35.0 : 0.0),
        completedAt: isCompleted ? DateTime.now().subtract(Duration(days: index + 1)) : null,
        lastAccessed: (isCompleted || isCurrent) ? DateTime.now().subtract(Duration(hours: index + 1)) : null,
      );
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            TextbookDetailHeader(textbook: widget.textbook),
            BackNavigationBar(
              title: 'Back to Scanner',
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextbookOverviewCard(textbook: widget.textbook),
                    ProgressTrackingSection(progress: progress),
                    StudyToolsGrid(textbook: widget.textbook),
                    KeyTopicsSection(topics: progress.keyTopics),
                    ChapterNavigationSection(
                      textbook: widget.textbook,
                      progress: progress,
                    ),
                    ContinueStudyingButton(
                      onPressed: () => _continueStudying(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _continueStudying(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/lesson-content',
      arguments: {
        'textbook': widget.textbook,
        'chapter': progress.currentChapter,
      },
    );
  }
}
class TextbookDetailHeader extends StatelessWidget {
  final UploadedTextbook textbook;
  const TextbookDetailHeader({
    super.key,
    required this.textbook,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Study',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text(
                  '7',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.notifications_outlined, color: Colors.grey[600]),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
class TextbookOverviewCard extends StatelessWidget {
  final UploadedTextbook textbook;
  const TextbookOverviewCard({
    super.key,
    required this.textbook,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textbook.title.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${textbook.fileSize}${textbook.totalPages > 0 ? ' • ${textbook.totalPages} pages' : ''}${textbook.subject != 'Unknown' ? ' • ${textbook.subject}' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class ProgressTrackingSection extends StatelessWidget {
  final TextbookProgress progress;
  const ProgressTrackingSection({
    super.key,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    final progressPercentage = progress.totalChapters > 0 
        ? (progress.completionPercentage.isFinite ? progress.completionPercentage.round() : 0)
        : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$progressPercentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.totalChapters > 0 
                ? (progress.completedChapters / progress.totalChapters).clamp(0.0, 1.0)
                : 0.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.totalChapters > 0 
                    ? '${progress.completedChapters}/${progress.totalChapters} chapters completed'
                    : 'No chapters available yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.studyHours.toStringAsFixed(1)} hours total',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class StudyToolsGrid extends StatelessWidget {
  final UploadedTextbook textbook;
  const StudyToolsGrid({
    super.key,
    required this.textbook,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: [
          StudyToolButton(
            title: 'Generate Flashcards',
            icon: Icons.style,
            backgroundColor: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: () => _generateFlashcards(context),
          ),
          StudyToolButton(
            title: 'Create Quiz',
            icon: Icons.quiz,
            backgroundColor: Colors.teal,
            textColor: Colors.white,
            onPressed: () => _createQuiz(context),
          ),
          StudyToolButton(
            title: 'Ask AI Tutor',
            icon: Icons.chat,
            backgroundColor: Colors.grey[100]!,
            textColor: Colors.black87,
            onPressed: () => _askAITutor(context),
          ),
          StudyToolButton(
            title: 'Summarize',
            icon: Icons.auto_awesome,
            backgroundColor: Colors.grey[100]!,
            textColor: Colors.black87,
            onPressed: () => _summarizeContent(context),
          ),
        ],
      ),
    );
  }
  void _generateFlashcards(BuildContext context) {
    Navigator.pushNamed(context, '/create-flashcard', arguments: textbook);
  }
  void _createQuiz(BuildContext context) {
    Navigator.pushNamed(context, '/quiz', arguments: textbook);
  }
  void _askAITutor(BuildContext context) {
    Navigator.pushNamed(context, '/tutor-chat', arguments: textbook);
  }
  void _summarizeContent(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summarize feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
class StudyToolButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  const StudyToolButton({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
class KeyTopicsSection extends StatelessWidget {
  final List<String> topics;
  const KeyTopicsSection({
    super.key,
    required this.topics,
  });
  @override
  Widget build(BuildContext context) {
    final displayTopics = topics.isNotEmpty 
        ? topics 
        : ['Document Analysis', 'Key Concepts', 'Study Materials'];
    
    final hasRealTopics = topics.isNotEmpty;
        
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Row(
            children: [
              const Text(
                'Key Topics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (!hasRealTopics) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto-generated',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI Extracted',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayTopics.map((topic) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasRealTopics 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: hasRealTopics 
                    ? null 
                    : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                topic,
                style: TextStyle(
                  color: hasRealTopics 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
class ChapterNavigationSection extends StatelessWidget {
  final UploadedTextbook textbook;
  final TextbookProgress progress;
  const ChapterNavigationSection({
    super.key,
    required this.textbook,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Row(
            children: [
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (textbook.chapters.isEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Generated',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI Extracted',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: progress.chapterProgresses.length,
            itemBuilder: (context, index) => ChapterListItem(
              chapterProgress: progress.chapterProgresses[index],
              isCurrent: progress.chapterProgresses[index].chapterNumber == progress.currentChapter,
              onTap: () => _openChapter(context, progress.chapterProgresses[index].chapterNumber),
            ),
          ),
        ],
      ),
    );
  }
  void _openChapter(BuildContext context, int chapterNumber) {
    Navigator.pushNamed(
      context,
      '/lesson-content',
      arguments: {
        'textbook': textbook,
        'chapter': chapterNumber,
      },
    );
  }
}
class ChapterListItem extends StatelessWidget {
  final ChapterProgress chapterProgress;
  final bool isCurrent;
  final VoidCallback onTap;
  const ChapterListItem({
    super.key,
    required this.chapterProgress,
    required this.isCurrent,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrent ? Colors.grey[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isCurrent ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: chapterProgress.isCompleted 
                      ? Colors.green 
                      : (isCurrent ? Theme.of(context).primaryColor : Colors.grey[300]),
                  shape: BoxShape.circle,
                ),
                child: chapterProgress.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Center(
                        child: Text(
                          '${chapterProgress.chapterNumber}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapterProgress.chapterTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          chapterProgress.pageRange,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${chapterProgress.estimatedReadingTimeMinutes} min',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent && chapterProgress.progressPercentage > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: chapterProgress.progressPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ContinueStudyingButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ContinueStudyingButton({
    super.key,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow, size: 24),
        label: const Text(
          'Continue Studying',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}