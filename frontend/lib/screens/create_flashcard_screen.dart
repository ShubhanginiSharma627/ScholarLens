import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../widgets/common/top_navigation_bar.dart';
class CreateFlashcardScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialCategory;
  const CreateFlashcardScreen({
    super.key,
    this.initialSubject,
    this.initialCategory,
  });
  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}
class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _subjectController = TextEditingController();
  final _categoryController = TextEditingController();
  final _flashcardService = FlashcardService();
  List<String> _existingSubjects = [];
  List<String> _existingCategories = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.initialSubject ?? '';
    _categoryController.text = widget.initialCategory ?? '';
    _loadExistingData();
  }
  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _subjectController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
  Future<void> _loadExistingData() async {
    final subjects = await _flashcardService.getSubjects();
    final categories = await _flashcardService.getCategories();
    setState(() {
      _existingSubjects = subjects;
      _existingCategories = categories;
    });
  }
  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final flashcard = Flashcard.create(
        subject: _subjectController.text.trim(),
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
      );
      await _flashcardService.createFlashcard(flashcard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating flashcard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _clearForm() {
    _questionController.clear();
    _answerController.clear();
    _subjectController.clear();
    _categoryController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationBar(
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Form'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSubjectField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 24),
            _buildQuestionField(),
            const SizedBox(height: 16),
            _buildAnswerField(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveFlashcard,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Flashcard'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTipsCard(),
          ],
        ),
      ),
    );
  }
  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _existingSubjects;
            }
            return _existingSubjects.where((subject) =>
                subject.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _subjectController.text = controller.text;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'e.g., Mathematics, Science, History',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subject is required';
                }
                return null;
              },
              onChanged: (value) => _subjectController.text = value,
            );
          },
        ),
      ],
    );
  }
  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _existingCategories;
            }
            return _existingCategories.where((category) =>
                category.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _categoryController.text = controller.text;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'e.g., Algebra, Biology, World War II',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              onChanged: (value) => _categoryController.text = value,
            );
          },
        ),
      ],
    );
  }
  Widget _buildQuestionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _questionController,
          decoration: const InputDecoration(
            hintText: 'Enter your question here...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.help_outline),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Question is required';
            }
            if (value.trim().length < 3) {
              return 'Question must be at least 3 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }
  Widget _buildAnswerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _answerController,
          decoration: const InputDecoration(
            hintText: 'Enter the answer here...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lightbulb_outline),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Answer is required';
            }
            if (value.trim().length < 2) {
              return 'Answer must be at least 2 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }
  Widget _buildTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for Better Flashcards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Keep questions clear and specific'),
            const SizedBox(height: 4),
            const Text('• Make answers concise but complete'),
            const SizedBox(height: 4),
            const Text('• Use categories to organize related cards'),
            const SizedBox(height: 4),
            const Text('• Include examples in your answers when helpful'),
          ],
        ),
      ),
    );
  }
}