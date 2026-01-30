import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../widgets/common/polished_components.dart';
import 'textbook_detail_screen.dart';

/// Syllabus Scanner screen that allows users to upload textbooks and PDFs
class SyllabusScannerScreen extends StatefulWidget {
  const SyllabusScannerScreen({super.key});

  @override
  State<SyllabusScannerScreen> createState() => _SyllabusScannerScreenState();
}

class _SyllabusScannerScreenState extends State<SyllabusScannerScreen> {
  List<UploadedTextbook> uploadedTextbooks = [];
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUploadedTextbooks();
  }

  void _loadUploadedTextbooks() async {
    try {
      // Load uploaded textbooks from storage
      final files = await _storageService.listFiles(folder: 'syllabus');
      
      setState(() {
        uploadedTextbooks = files.map((file) => UploadedTextbook(
          id: file.name,
          title: file.originalName.replaceAll('.pdf', ''),
          fileName: file.originalName,
          fileSize: file.formattedSize,
          status: TextbookStatus.ready,
          uploadedAt: file.timeCreated,
          chapters: [], // Will be populated after analysis
          totalPages: 0, // Will be populated after analysis
          keyTopics: [], // Will be populated after analysis
          subject: 'Unknown', // Will be determined after analysis
        )).toList();
      });
    } catch (e) {
      // Fall back to mock data if storage fails
      setState(() {
        uploadedTextbooks = [
          UploadedTextbook(
            id: '1',
            title: 'Biology Textbook',
            fileName: 'Biology_Grade_12.pdf',
            fileSize: '24.5 MB',
            status: TextbookStatus.ready,
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
            chapters: ['Cell Structure', 'Mitosis', 'DNA Replication', 'Photosynthesis', 'Genetics'],
            totalPages: 156,
            keyTopics: ['Cell Structure', 'Mitosis', 'DNA Replication', 'Photosynthesis'],
            subject: 'Biology',
          ),
          UploadedTextbook(
            id: '2',
            title: 'Physics Textbook',
            fileName: 'Physics_Fundamentals.pdf',
            fileSize: '18.2 MB',
            status: TextbookStatus.ready,
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            chapters: ['Newton\'s Laws', 'Kinematics', 'Work & Energy'],
            totalPages: 124,
            keyTopics: ['Newton\'s Laws', 'Kinematics', 'Work & Energy'],
            subject: 'Physics',
          ),
        ];
      });
    }
  }

  Future<void> _handleFileUpload(File file) async {
    if (!_storageService.isSupportedFileType(file)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported file type. Please select a PDF file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload and scan the syllabus
      final analysisResult = await _storageService.uploadAndScanSyllabus(
        file: file,
        prompt: 'Analyze this syllabus and extract key information including chapters, topics, and subject area.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syllabus uploaded and analyzed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload textbooks to show the new upload
      _loadUploadedTextbooks();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const SyllabusHeader(),
            BackNavigationBar(
              title: 'Back to Home',
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    UploadInterface(
                      isUploading: _isUploading,
                      uploadProgress: _uploadProgress,
                      onFileSelected: _handleFileUpload,
                    ),
                    YourTextbooksSection(textbooks: uploadedTextbooks),
                    const GeminiTextbookPromotionCard(),
                    const TextbookFeaturesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header section with title and subtitle
class SyllabusHeader extends StatelessWidget {
  const SyllabusHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Syllabus Scanner',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload textbooks and let Gemini 1.5 Pro analyze up to 1M tokens',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Upload interface with drag and drop area
class UploadInterface extends StatelessWidget {
  final bool isUploading;
  final double uploadProgress;
  final Function(File) onFileSelected;

  const UploadInterface({
    super.key,
    required this.isUploading,
    required this.uploadProgress,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
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
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.upload_file,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Drop your textbook here',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports PDF files up to 100MB. Gemini 1.5 Pro can read entire textbooks!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (isUploading) ...[
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Uploading... ${(uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () => _chooseFile(context),
              icon: const Icon(Icons.upload),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _chooseFile(BuildContext context) async {
    if (isUploading) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && context.mounted) {
        PlatformFile platformFile = result.files.first;
        
        if (platformFile.path != null) {
          File file = File(platformFile.path!);
          onFileSelected(file);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to access selected file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Your textbooks section with uploaded files
class YourTextbooksSection extends StatelessWidget {
  final List<UploadedTextbook> textbooks;

  const YourTextbooksSection({
    super.key,
    required this.textbooks,
  });

  @override
  Widget build(BuildContext context) {
    if (textbooks.isEmpty) {
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
                Icons.menu_book,
                size: 32,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No textbooks uploaded yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your first textbook to get started!',
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
            'Your Textbooks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: textbooks.length,
          itemBuilder: (context, index) => TextbookCard(textbook: textbooks[index]),
        ),
      ],
    );
  }
}

/// Individual textbook card
class TextbookCard extends StatelessWidget {
  final UploadedTextbook textbook;

  const TextbookCard({
    super.key,
    required this.textbook,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textbook.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          textbook.fileSize,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _studyTextbook(context, textbook),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Study'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: textbook.chapters.map((chapter) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    chapter,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _studyTextbook(BuildContext context, UploadedTextbook textbook) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextbookDetailScreen(textbook: textbook),
      ),
    );
  }
}

/// Gemini promotion card for textbook processing
class GeminiTextbookPromotionCard extends StatelessWidget {
  const GeminiTextbookPromotionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Icons.menu_book,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Powered by Gemini 1.5 Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Process entire textbooks with up to 1 million token context window. Get summaries, generate flashcards, and ask questions about any content.',
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

/// Features card showing what users can do
class TextbookFeaturesCard extends StatelessWidget {
  const TextbookFeaturesCard({super.key});

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
          Text(
            'What you can do:',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.summarize,
            text: 'Generate chapter summaries',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.style,
            text: 'Create flashcards from content',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.help_outline,
            text: 'Ask questions about the material',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.quiz,
            text: 'Generate practice quizzes',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}