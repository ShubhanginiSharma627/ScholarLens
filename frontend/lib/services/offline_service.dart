import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lesson_content.dart';
import '../models/quiz_question.dart';
class OfflineServiceException implements Exception {
  final String message;
  final String? details;
  const OfflineServiceException(this.message, {this.details});
  @override
  String toString() {
    return 'OfflineServiceException: $message${details != null ? ' - $details' : ''}';
  }
}
class OfflineService {
  static OfflineService? _instance;
  static OfflineService get instance => _instance ??= OfflineService._();
  OfflineService._();
  bool _isOfflineMode = false;
  final StreamController<bool> _offlineModeController = StreamController<bool>.broadcast();
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  bool get isOfflineMode => _isOfflineMode;
  Future<void> activateOfflineMode() async {
    if (!_isOfflineMode) {
      _isOfflineMode = true;
      _offlineModeController.add(true);
      debugPrint('Offline mode activated');
    }
  }
  Future<void> deactivateOfflineMode() async {
    if (_isOfflineMode) {
      _isOfflineMode = false;
      _offlineModeController.add(false);
      debugPrint('Offline mode deactivated');
    }
  }
  Future<bool> checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (isConnected && _isOfflineMode) {
        await deactivateOfflineMode();
      } else if (!isConnected && !_isOfflineMode) {
        await activateOfflineMode();
      }
      return isConnected;
    } catch (e) {
      if (!_isOfflineMode) {
        await activateOfflineMode();
      }
      return false;
    }
  }
  Future<LessonContent> getDemoLesson() async {
    try {
      return LessonContent(
        lessonTitle: 'Photosynthesis: The Foundation of Life',
        summaryMarkdown: _getPhotosynthesisSummary(),
        audioTranscript: _getPhotosynthesisAudioTranscript(),
        quiz: _getPhotosynthesisQuiz(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw OfflineServiceException(
        'Failed to load demo lesson',
        details: e.toString(),
      );
    }
  }
  Future<List<String>> getAvailableDemoLessons() async {
    return [
      'Photosynthesis: The Foundation of Life',
    ];
  }
  Future<LessonContent?> getDemoLessonByTitle(String title) async {
    switch (title) {
      case 'Photosynthesis: The Foundation of Life':
        return getDemoLesson();
      default:
        return null;
    }
  }
  void dispose() {
    _offlineModeController.close();
  }
  String _getPhotosynthesisSummary() {
    return '''
# Photosynthesis: The Foundation of Life
## Overview
Photosynthesis is the biological process by which plants, algae, and some bacteria convert light energy (usually from the sun) into chemical energy stored in glucose molecules. This process is fundamental to life on Earth as it produces oxygen and serves as the primary source of energy for most ecosystems.
## The Chemical Equation
The overall equation for photosynthesis is:
**6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂**
- **Reactants**: Carbon dioxide (CO₂) and water (H₂O)
- **Products**: Glucose (C₆H₁₂O₆) and oxygen (O₂)
- **Energy source**: Light (usually sunlight)
## Two Main Stages
### 1. Light-Dependent Reactions (The Photo Part)
- **Location**: Thylakoid membranes of chloroplasts
- **Process**: Chlorophyll absorbs light energy
- **Products**: ATP, NADPH, and oxygen
- **Key events**:
  - Water molecules are split (photolysis)
  - Oxygen is released as a byproduct
  - Energy is captured in ATP and NADPH
### 2. Light-Independent Reactions (The Calvin Cycle)
- **Location**: Stroma of chloroplasts
- **Process**: Uses ATP and NADPH from light reactions
- **Products**: Glucose (sugar)
- **Key events**:
  - CO₂ is "fixed" into organic molecules
  - Glucose is synthesized through a series of enzyme reactions
  - ATP and NADPH provide the energy and electrons needed
## Importance of Photosynthesis
### For Plants
- Provides energy for growth and metabolism
- Creates structural materials (cellulose, starch)
- Enables survival and reproduction
### For Ecosystems
- **Primary production**: Forms the base of food chains
- **Oxygen production**: Maintains atmospheric oxygen levels
- **Carbon dioxide removal**: Helps regulate atmospheric CO₂
- **Energy conversion**: Converts solar energy into chemical energy
### For Humans
- **Food source**: All food ultimately derives from photosynthesis
- **Oxygen supply**: Provides the oxygen we breathe
- **Climate regulation**: Helps control global carbon cycle
- **Economic value**: Agriculture, forestry, and many industries depend on it
## Factors Affecting Photosynthesis
1. **Light intensity**: More light generally increases the rate (up to a saturation point)
2. **Carbon dioxide concentration**: Higher CO₂ levels can increase the rate
3. **Temperature**: Affects enzyme activity (optimal range varies by species)
4. **Water availability**: Essential for the light reactions
5. **Chlorophyll content**: More chlorophyll can capture more light
## Adaptations in Different Environments
### C3 Plants (Most common)
- Standard photosynthesis pathway
- Examples: wheat, rice, soybeans
- Less efficient in hot, dry conditions
### C4 Plants
- Modified pathway for hot, dry climates
- Examples: corn, sugarcane, sorghum
- More efficient water and CO₂ use
### CAM Plants
- Open stomata at night to collect CO₂
- Examples: cacti, pineapples, agave
- Extreme water conservation adaptation
## Conclusion
Photosynthesis is truly the foundation of life on Earth. Without this remarkable process, our planet would be a lifeless rock. Understanding photosynthesis helps us appreciate the interconnectedness of all living things and the critical role that plants play in maintaining the conditions necessary for life as we know it.
''';
  }
  String _getPhotosynthesisAudioTranscript() {
    return '''
Welcome to our lesson on photosynthesis, one of the most important biological processes on Earth.
Photosynthesis is how plants convert sunlight into food. Think of it as nature's solar power system. Plants take in carbon dioxide from the air, water from their roots, and energy from sunlight to create glucose sugar and release oxygen.
The chemical equation is: six carbon dioxide plus six water plus light energy produces glucose plus six oxygen molecules.
This process happens in two main stages. First, the light-dependent reactions occur in the thylakoids, where chlorophyll captures light energy and splits water molecules, releasing oxygen. Second, the Calvin cycle uses that captured energy to build glucose from carbon dioxide.
Why is this so important? Photosynthesis produces all the oxygen we breathe and forms the foundation of nearly every food chain on Earth. Without photosynthesis, life as we know it simply couldn't exist.
Different plants have evolved different strategies. C3 plants use the standard pathway, C4 plants are more efficient in hot climates, and CAM plants like cacti can photosynthesize while conserving water in desert conditions.
Understanding photosynthesis helps us appreciate how interconnected all life is and why protecting plant life is so crucial for our planet's future.
''';
  }
  List<QuizQuestion> _getPhotosynthesisQuiz() {
    return [
      QuizQuestion(
        question: 'What is the primary purpose of photosynthesis?',
        options: [
          'To produce oxygen for animals',
          'To convert light energy into chemical energy',
          'To remove carbon dioxide from the atmosphere',
          'To create water for the plant'
        ],
        correctIndex: 1,
        explanation: 'The primary purpose of photosynthesis is to convert light energy into chemical energy (glucose) that plants can use for growth and metabolism. While oxygen production and CO₂ removal are important byproducts, energy conversion is the main function.',
      ),
      QuizQuestion(
        question: 'Where do the light-dependent reactions of photosynthesis occur?',
        options: [
          'In the stroma of chloroplasts',
          'In the thylakoid membranes',
          'In the cell nucleus',
          'In the mitochondria'
        ],
        correctIndex: 1,
        explanation: 'Light-dependent reactions occur in the thylakoid membranes of chloroplasts, where chlorophyll molecules are embedded and can capture light energy effectively.',
      ),
      QuizQuestion(
        question: 'What are the main products of the Calvin cycle?',
        options: [
          'ATP and NADPH',
          'Oxygen and water',
          'Glucose and other sugars',
          'Carbon dioxide and light energy'
        ],
        correctIndex: 2,
        explanation: 'The Calvin cycle (light-independent reactions) produces glucose and other sugars by fixing carbon dioxide using the ATP and NADPH generated in the light-dependent reactions.',
      ),
      QuizQuestion(
        question: 'Which type of plant is most efficient in hot, dry climates?',
        options: [
          'C3 plants',
          'C4 plants',
          'CAM plants',
          'All plants are equally efficient'
        ],
        correctIndex: 2,
        explanation: 'CAM (Crassulacean Acid Metabolism) plants are most efficient in hot, dry climates because they open their stomata at night to collect CO₂, minimizing water loss during the hot day.',
      ),
      QuizQuestion(
        question: 'What happens to water molecules during the light-dependent reactions?',
        options: [
          'They are converted to glucose',
          'They are split to release oxygen',
          'They are stored for later use',
          'They combine with CO₂'
        ],
        correctIndex: 1,
        explanation: 'During photolysis in the light-dependent reactions, water molecules are split (H₂O → 2H⁺ + ½O₂ + 2e⁻), releasing oxygen as a byproduct and providing electrons for the photosynthetic process.',
      ),
    ];
  }
}