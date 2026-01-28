import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recent_snap.dart';
import '../animations/camera_animations.dart';

/// Detailed view screen for a specific snap showing AI solution and explanation
class SnapDetailsScreen extends StatefulWidget {
  final RecentSnap snap;
  final String? imagePath;

  const SnapDetailsScreen({
    super.key,
    required this.snap,
    this.imagePath,
  });

  @override
  State<SnapDetailsScreen> createState() => _SnapDetailsScreenState();
}

class _SnapDetailsScreenState extends State<SnapDetailsScreen>
    with TickerProviderStateMixin {
  bool? wasHelpful;
  String detectedQuestion = '';
  String aiAnswer = '';
  String explanation = '';
  List<String> stepByStepSolution = [];
  
  late AnimationController _revealController;
  late AnimationController _successController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _loadSnapDetails();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadSnapDetails() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Load actual snap details from backend using widget.snap.lessonId
    // For now, using mock data based on the subject
    setState(() {
      if (widget.snap.subject.toLowerCase() == 'algebra') {
        detectedQuestion = 'Solve: 2x² + 5x - 3 = 0';
        aiAnswer = 'x = 0.5 or x = -3';
        explanation = 'This is a quadratic equation that can be solved using the quadratic formula or factoring.';
        stepByStepSolution = [
          'First, let\'s identify a=2, b=5, c=-3',
          'Using the quadratic formula: x = (-b ± √(b²-4ac)) / 2a',
          'x = (-5 ± √(25+24)) / 4',
          'x = (-5 ± 7) / 4',
          'Therefore: x = 0.5 or x = -3',
        ];
      } else if (widget.snap.subject.toLowerCase() == 'biology') {
        detectedQuestion = 'Explain the process of photosynthesis';
        aiAnswer = '6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂';
        explanation = 'Photosynthesis is the process by which plants convert light energy into chemical energy.';
        stepByStepSolution = [
          'Light-dependent reactions occur in the thylakoids',
          'Chlorophyll absorbs light energy',
          'Water molecules are split to release oxygen',
          'ATP and NADPH are produced',
          'Calvin cycle uses CO₂ to produce glucose',
        ];
      } else {
        detectedQuestion = 'Calculate the force using Newton\'s second law';
        aiAnswer = 'F = ma = 10 × 2 = 20 N';
        explanation = 'Newton\'s second law states that force equals mass times acceleration.';
        stepByStepSolution = [
          'Identify the given values: m = 10 kg, a = 2 m/s²',
          'Apply Newton\'s second law: F = ma',
          'Substitute the values: F = 10 × 2',
          'Calculate the result: F = 20 N',
        ];
      }
      _isLoading = false;
    });
    
    // Start reveal animation
    await CameraAnimations.triggerResultsReveal(_revealController);
    
    // Show success animation after reveal
    await Future.delayed(const Duration(milliseconds: 200));
    await CameraAnimations.triggerSuccessAnimation(_successController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : SingleChildScrollView(
                      child: CameraAnimations.createEnhancedResultsReveal(
                        controller: _revealController,
                        child: Column(
                          children: [
                            _buildImageSection(),
                            _buildSubjectAndTime(),
                            _buildDetectedQuestion(),
                            _buildAISolution(),
                            _buildFeedbackSection(),
                            _buildActionButtons(),
                            _buildSolveAnotherButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          SizedBox(height: 16),
          Text(
            'Processing your snap...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Snap Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flash_on,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  '7',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF7C3AED),
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                widget.imagePath!,
                fit: BoxFit.cover,
              ),
            )
          : const Center(
              child: Icon(
                Icons.image,
                size: 80,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildSubjectAndTime() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.snap.subject,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _formatDateTime(widget.snap.createdAt),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedQuestion() {
    return Container(
      width: double.infinity,
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
          Text(
            'Detected Question',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detectedQuestion,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISolution() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Answer highlight box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aiAnswer,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Explanation
          Text(
            'Explanation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Step-by-step solution
          Text(
            'Step-by-Step Solution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          
          ...stepByStepSolution.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                        '$index',
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
                      step,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      width: double.infinity,
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
          Text(
            'Was this helpful?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => wasHelpful = true),
                  icon: Icon(
                    Icons.thumb_up,
                    size: 20,
                    color: wasHelpful == true ? Colors.white : Colors.grey[600],
                  ),
                  label: Text(
                    'Yes',
                    style: TextStyle(
                      color: wasHelpful == true ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: wasHelpful == true ? const Color(0xFF16A34A) : Colors.transparent,
                    foregroundColor: wasHelpful == true ? Colors.white : Colors.grey[600],
                    side: BorderSide(
                      color: wasHelpful == true ? const Color(0xFF16A34A) : Colors.grey[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => wasHelpful = false),
                  icon: Icon(
                    Icons.thumb_down,
                    size: 20,
                    color: wasHelpful == false ? Colors.white : Colors.grey[600],
                  ),
                  label: Text(
                    'No',
                    style: TextStyle(
                      color: wasHelpful == false ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: wasHelpful == false ? const Color(0xFFDC2626) : Colors.transparent,
                    foregroundColor: wasHelpful == false ? Colors.white : Colors.grey[600],
                    side: BorderSide(
                      color: wasHelpful == false ? const Color(0xFFDC2626) : Colors.grey[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('Copy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saveSnap,
              icon: const Icon(Icons.bookmark_border, size: 20),
              label: const Text('Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareSnap,
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolveAnotherButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _solveAnotherProblem,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Solve Another Problem'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final snapDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (snapDate == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (snapDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _copyToClipboard() {
    final content = '''
Question: $detectedQuestion

Answer: $aiAnswer

Explanation: $explanation

Step-by-Step Solution:
${stepByStepSolution.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}
''';
    
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solution copied to clipboard'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _saveSnap() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Snap saved to your collection'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _shareSnap() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  void _solveAnotherProblem() {
    // Navigate back to Snap & Solve screen
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: Navigate to specific tab if needed
  }
}