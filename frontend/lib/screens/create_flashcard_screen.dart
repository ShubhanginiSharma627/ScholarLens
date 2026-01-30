import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
class CreateFlashcardScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialCategory;
  final String? initialTopic;
  const CreateFlashcardScreen({
    super.key,
    this.initialSubject,
    this.initialCategory,
    this.initialTopic,
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
  final _topicController = TextEditingController();
  final _flashcardService = FlashcardService();
  
  List<String> _existingSubjects = [];
  List<String> _existingCategories = [];
  bool _isLoading = false;
  
  String _generationMode = 'manual';
  
  ScaffoldMessengerState? _scaffoldMessenger;
  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.initialSubject ?? '';
    _categoryController.text = widget.initialCategory ?? '';
    
    if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      _generationMode = 'ai';
      _topicController.text = widget.initialTopic!;
    } else if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      _generationMode = 'ai';
      _topicController.text = widget.initialSubject!;
    }
    
    _loadExistingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }
  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _subjectController.dispose();
    _categoryController.dispose();
    _topicController.dispose();
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

  void _showSnackBar(SnackBar snackBar) {
    try {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.clearSnackBars();
        _scaffoldMessenger!.showSnackBar(snackBar);
      }
    } catch (e) {
      debugPrint('Could not show snackbar: $e');
    }
  }
  Future<void> _saveFlashcard() async {
    print('=== _saveFlashcard called ===');
    print('Generation mode: $_generationMode');
    print('Form valid: ${_formKey.currentState?.validate()}');
    
    if (!_formKey.currentState!.validate()) return;

    print('Form validation passed, starting save process...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_generationMode == 'manual') {
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
          _showSnackBar(
            const SnackBar(
              content: Text('Flashcard created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
        
          _showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Generating flashcards with AI...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 10), 
            ),
          );
        }
        
        try {
          final topic = _topicController.text.trim();
          final subject = _subjectController.text.trim();
          final category = _categoryController.text.trim().isEmpty 
              ? null 
              : _categoryController.text.trim();
              
          print('=== AI GENERATION DEBUG ===');
          print('Topic: $topic');
          print('Subject: $subject'); 
          print('Category: $category');
          print('Starting AI generation...');
          
          final generatedCards = await _flashcardService.generateFlashcardsWithAI(
            topic: topic,
            subject: subject,
            category: category,
            count: 5,
          );
          
          print('Generated ${generatedCards.length} flashcards successfully');
          print('Cards: ${generatedCards.map((c) => c.question).toList()}');
          
        
          if (mounted) {
            
            _scaffoldMessenger?.clearSnackBars();
            _showSnackBar(
              SnackBar(
                content: Text('Generated ${generatedCards.length} flashcards successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('=== AI GENERATION ERROR ===');
          print('Error type: ${e.runtimeType}');
          print('Error message: $e');
          print('Stack trace: ${StackTrace.current}');
          
         
          if (mounted) {
            
            _scaffoldMessenger?.clearSnackBars();
            _showSnackBar(
              SnackBar(
                content: Text('Failed to generate flashcards: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    if (mounted) {
                      _saveFlashcard();
                    }
                  },
                ),
              ),
            );
          }
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }
      
    
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('=== GENERAL ERROR ===');
      print('Error: $e');
      
      if (mounted) {
       
        _scaffoldMessenger?.clearSnackBars();
        _showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    _topicController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTopic != null 
              ? 'Generate Cards: ${widget.initialTopic}'
              : widget.initialSubject != null 
                  ? 'Generate ${widget.initialSubject} Cards'
                  : 'Create Flashcard',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Form(
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
                _buildGenerationModeSelector(),
                const SizedBox(height: 16),
                _buildSubjectField(),
                const SizedBox(height: 16),
                _buildCategoryField(),
                const SizedBox(height: 24),
                if (_generationMode == 'manual') ...[
                  _buildQuestionField(),
                  const SizedBox(height: 16),
                  _buildAnswerField(),
                ] else ...[
                  _buildTopicField(),
                ],
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
                            : Text(_generationMode == 'manual' ? 'Create Flashcard' : 'Generate Cards'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTipsCard(),
              ],
            ),
          ),
          if (_isLoading && _generationMode == 'ai')
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Generating flashcards...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI is creating cards based on your topic',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerationModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Generation Mode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Manual Creation'),
                subtitle: const Text('Create cards by entering question and answer'),
                value: 'manual',
                groupValue: _generationMode,
                onChanged: (value) {
                  setState(() {
                    _generationMode = value!;
                  });
                },
                secondary: const Icon(Icons.edit),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('AI Generation'),
                subtitle: const Text('Generate multiple cards from a topic using AI'),
                value: 'ai',
                groupValue: _generationMode,
                onChanged: (value) {
                  setState(() {
                    _generationMode = value!;
                  });
                },
                secondary: const Icon(Icons.auto_awesome),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic for AI Generation *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _topicController,
          decoration: InputDecoration(
            hintText: widget.initialSubject != null 
                ? 'e.g., ${_getTopicSuggestion(widget.initialSubject!)}'
                : 'e.g., Photosynthesis, Quadratic Equations, World War II',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.topic),
            helperText: 'AI will generate multiple flashcards based on this topic',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Topic is required for AI generation';
            }
            if (value.trim().length < 3) {
              return 'Topic must be at least 3 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getTopicSuggestion(String subject) {
    final suggestions = {
      'Computer Science': 'Data Structures, Algorithms, Object-Oriented Programming',
      'Mathematics': 'Calculus, Linear Algebra, Statistics',
      'Physics': 'Quantum Mechanics, Thermodynamics, Electromagnetism',
      'Chemistry': 'Organic Chemistry, Chemical Bonding, Periodic Table',
      'Biology': 'Cell Biology, Genetics, Evolution',
      'History': 'World War II, Renaissance, Industrial Revolution',
      'English': 'Shakespeare, Grammar, Literary Analysis',
      'Psychology': 'Cognitive Psychology, Behavioral Psychology, Memory',
      'Economics': 'Microeconomics, Macroeconomics, Market Structures',
    };
    
    return suggestions[subject] ?? 'Advanced topics in $subject';
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
                  _generationMode == 'manual' 
                      ? 'Tips for Better Flashcards'
                      : 'Tips for AI Generation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_generationMode == 'manual') ...[
              const Text('• Keep questions clear and specific'),
              const SizedBox(height: 4),
              const Text('• Make answers concise but complete'),
              const SizedBox(height: 4),
              const Text('• Use categories to organize related cards'),
              const SizedBox(height: 4),
              const Text('• Include examples in your answers when helpful'),
            ] else ...[
              if (widget.initialSubject != null) ...[
                Text('• Generating more cards for ${widget.initialSubject}'),
                const SizedBox(height: 4),
              ],
              const Text('• Be specific with your topic for better results'),
              const SizedBox(height: 4),
              const Text('• AI will generate 5-10 cards per topic'),
              const SizedBox(height: 4),
              const Text('• Include context like "for beginners" if needed'),
              const SizedBox(height: 4),
              const Text('• Review and edit generated cards as needed'),
            ],
          ],
        ),
      ),
    );
  }
}