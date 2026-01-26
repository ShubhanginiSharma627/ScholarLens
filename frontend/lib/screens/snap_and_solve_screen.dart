import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/models.dart';
import '../widgets/common/polished_components.dart';
import 'camera_screen.dart';
import 'snap_details_screen.dart';

/// Snap & Solve screen that allows users to capture or upload problems
class SnapAndSolveScreen extends StatefulWidget {
  const SnapAndSolveScreen({super.key});

  @override
  State<SnapAndSolveScreen> createState() => _SnapAndSolveScreenState();
}

class _SnapAndSolveScreenState extends State<SnapAndSolveScreen> {
  List<RecentSnap> recentSnaps = [];
  File? capturedImage;
  bool isAnalyzing = false;
  bool hasAnalyzed = false;
  String? aiSolution;

  @override
  void initState() {
    super.initState();
    _loadRecentSnaps();
  }

  void _loadRecentSnaps() {
    // TODO: Load recent snaps from storage/service
    // For now, using mock data
    setState(() {
      recentSnaps = [
        RecentSnap(
          id: '1',
          problemTitle: 'Quadratic Equation Solution',
          subject: 'Algebra',
          lessonId: 'lesson_1',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RecentSnap(
          id: '2',
          problemTitle: 'Photosynthesis Process',
          subject: 'Biology',
          lessonId: 'lesson_2',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RecentSnap(
          id: '3',
          problemTitle: 'Newton\'s Laws of Motion',
          subject: 'Physics',
          lessonId: 'lesson_3',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    });
  }

  void _onImageCaptured(File image) {
    setState(() {
      capturedImage = image;
      hasAnalyzed = false;
      aiSolution = null;
    });
  }

  void _analyzeWithAI() async {
    if (capturedImage == null) return;
    
    setState(() {
      isAnalyzing = true;
    });

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isAnalyzing = false;
      hasAnalyzed = true;
      aiSolution = '''Detected Question

Solve the quadratic equation: 2x² + 5x - 3 = 0

Explanation

This is a quadratic equation that can be solved using the quadratic formula or factoring.

Step-by-Step Solution

1. First, let's identify a=2, b=5, c=-3

2. Using the quadratic formula: x = (-b ± √(b²-4ac)) / 2a

3. x = (-5 ± √(25+24)) / 4

4. x = (-5 ± 7) / 4

5. Therefore: x = 0.5 or x = -3''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            SnapSolveHeader(
              capturedImage: capturedImage,
              isAnalyzing: isAnalyzing,
              hasAnalyzed: hasAnalyzed,
              onChangeImage: () => _showImageOptions(context),
              onAnalyzeWithAI: _analyzeWithAI,
            ),
            BackNavigationBar(
              title: 'Back to Home',
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (capturedImage == null) ...[
                      CaptureInterface(onImageCaptured: _onImageCaptured),
                      RecentSnapsSection(snaps: recentSnaps),
                      const GeminiPromotionCard(),
                    ] else if (aiSolution != null) ...[
                      AISolutionCard(solution: aiSolution!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _takePhoto(BuildContext context) async {
    final result = await Navigator.of(context).push<ProcessedImage>(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
    
    if (result != null) {
      _onImageCaptured(result.file);
    }
  }

  void _uploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null && context.mounted) {
        _onImageCaptured(File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Header section with title and subtitle or captured image interface
class SnapSolveHeader extends StatelessWidget {
  final File? capturedImage;
  final bool isAnalyzing;
  final bool hasAnalyzed;
  final VoidCallback onChangeImage;
  final VoidCallback onAnalyzeWithAI;

  const SnapSolveHeader({
    super.key,
    this.capturedImage,
    this.isAnalyzing = false,
    this.hasAnalyzed = false,
    required this.onChangeImage,
    required this.onAnalyzeWithAI,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedImage != null) {
      return _buildImageInterface(context);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snap & Solve',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of any problem and get instant explanations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageInterface(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Image display area
          Container(
            width: double.infinity,
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    capturedImage!,
                    fit: BoxFit.cover,
                  ),
                  // Overlay for placeholder when no actual image
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onChangeImage,
                    icon: const Icon(Icons.image, size: 20),
                    label: const Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasAnalyzed ? null : (isAnalyzing ? null : onAnalyzeWithAI),
                    icon: isAnalyzing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 20),
                    label: Text(
                      isAnalyzing 
                          ? 'Analyzing...' 
                          : hasAnalyzed 
                              ? 'Analyzed' 
                              : 'Solve with AI'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAnalyzed 
                          ? Colors.grey[400] 
                          : const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
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

/// Main capture interface with camera icon and action buttons
class CaptureInterface extends StatelessWidget {
  final Function(File) onImageCaptured;

  const CaptureInterface({
    super.key,
    required this.onImageCaptured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Snap or Upload',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of a math equation, diagram, or any problem',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePhoto(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _uploadImage(context),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _takePhoto(BuildContext context) async {
    final result = await Navigator.of(context).push<ProcessedImage>(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
    
    if (result != null) {
      onImageCaptured(result.file);
    }
  }

  void _uploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null && context.mounted) {
        onImageCaptured(File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Gemini promotion card with gradient background
class GeminiPromotionCard extends StatelessWidget {
  const GeminiPromotionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gemini 1.5 Flash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Multimodal AI that can understand images, diagrams, equations, and handwritten notes instantly.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent snaps section with scrollable list
class RecentSnapsSection extends StatelessWidget {
  final List<RecentSnap> snaps;

  const RecentSnapsSection({
    super.key,
    required this.snaps,
  });

  @override
  Widget build(BuildContext context) {
    if (snaps.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera,
                size: 32,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent snaps yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your first problem to get started!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recent Snaps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snaps.length,
          itemBuilder: (context, index) => RecentSnapCard(snap: snaps[index]),
        ),
      ],
    );
  }
}

/// Individual recent snap card
class RecentSnapCard extends StatelessWidget {
  final RecentSnap snap;

  const RecentSnapCard({
    super.key,
    required this.snap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getSubjectColor(snap.subject).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSubjectIcon(snap.subject),
              color: _getSubjectColor(snap.subject),
              size: 24,
            ),
          ),
          title: Text(
            snap.problemTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSubjectColor(snap.subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  snap.subject,
                  style: TextStyle(
                    color: _getSubjectColor(snap.subject),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(snap.createdAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: () => _openSnapDetails(context, snap),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'algebra':
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'biology':
        return Icons.biotech;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'english':
      case 'literature':
        return Icons.menu_book;
      case 'geography':
        return Icons.public;
      default:
        return Icons.school;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'algebra':
      case 'math':
      case 'mathematics':
        return Colors.blue;
      case 'biology':
        return Colors.green;
      case 'physics':
        return Colors.orange;
      case 'chemistry':
        return Colors.purple;
      case 'history':
        return Colors.brown;
      case 'english':
      case 'literature':
        return Colors.indigo;
      case 'geography':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _openSnapDetails(BuildContext context, RecentSnap snap) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SnapDetailsScreen(
          snap: snap,
          imagePath: snap.thumbnailPath,
        ),
      ),
    );
  }
}

/// AI Solution display card
class AISolutionCard extends StatelessWidget {
  final String solution;

  const AISolutionCard({
    super.key,
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Solution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSolutionContent(solution),
        ],
      ),
    );
  }

  Widget _buildSolutionContent(String solution) {
    final lines = solution.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      if (line == 'Detected Question') {
        widgets.add(
          Text(
            line,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else if (line == 'Explanation' || line == 'Step-by-Step Solution') {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          Text(
            line,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith(RegExp(r'^\d+\.'))) {
        // Numbered step
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      line.split('.')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line.substring(line.indexOf('.') + 1).trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Text(
            line,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}