const { generateFlashcards, analyzeImageWithPrompt, generateText } = require('./vertexai.service');
const aiGenerationDB = require('./ai-generation-db.service');
const winston = require('winston');
const crypto = require('crypto');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/ai-generation.log' })
  ]
});

/**
 * AI Generation Service
 * Orchestrates the AI-powered flashcard generation process
 */
class AIGenerationService {
  
  /**
   * Process content and generate flashcards
   */
  async processContentAndGenerate(userId, contentSource, options = {}) {
    let session = null;
    
    try {
      // Create generation session
      session = await aiGenerationDB.createGenerationSession(userId, contentSource);
      
      // Track analytics
      await aiGenerationDB.trackAnalyticsEvent(
        userId, 
        session.id, 
        'generation_start', 
        { contentType: contentSource.type, options }
      );
      
      // Process content based on type
      let extractedContent;
      switch (contentSource.type) {
        case 'image':
          extractedContent = await this.processImageContent(contentSource);
          break;
        case 'pdf':
          extractedContent = await this.processPDFContent(contentSource);
          break;
        case 'text':
          extractedContent = await this.processTextContent(contentSource);
          break;
        case 'topic':
          extractedContent = await this.processTopicContent(contentSource);
          break;
        default:
          throw new Error(`Unsupported content type: ${contentSource.type}`);
      }
      
      // Validate extracted content
      const validation = this.validateContent(extractedContent);
      if (!validation.isValid) {
        throw new Error(`Content validation failed: ${validation.errors.join(', ')}`);
      }
      
      // Analyze content
      const analysis = await this.analyzeContent(extractedContent);
      
      // Generate flashcards
      const generationOptions = {
        count: options.count || 5,
        difficulty: options.difficulty || 'intermediate',
        subjects: options.subjects || [analysis.subjectArea],
        focusAreas: options.focusAreas || analysis.keyTopics,
        ...options
      };
      
      const generatedFlashcards = await this.generateFlashcardsFromAnalysis(
        analysis, 
        generationOptions
      );
      
      // Assess quality of generated flashcards
      const assessedFlashcards = await this.assessFlashcardQuality(generatedFlashcards);
      
      // Save generated flashcards
      await aiGenerationDB.saveGeneratedFlashcards(session.id, assessedFlashcards);
      
      // Update session status
      await aiGenerationDB.updateSessionStatus(session.id, 'generated');
      
      // Track completion analytics
      await aiGenerationDB.trackAnalyticsEvent(
        userId,
        session.id,
        'generation_complete',
        { 
          flashcardCount: assessedFlashcards.length,
          averageConfidence: this.calculateAverageConfidence(assessedFlashcards)
        }
      );
      
      return {
        sessionId: session.id,
        flashcards: assessedFlashcards,
        analysis,
        metadata: {
          contentType: contentSource.type,
          generatedCount: assessedFlashcards.length,
          averageConfidence: this.calculateAverageConfidence(assessedFlashcards)
        }
      };
      
    } catch (error) {
      logger.error('Content processing and generation failed:', error);
      
      if (session) {
        await aiGenerationDB.updateSessionStatus(session.id, 'failed', error.message);
        await aiGenerationDB.trackAnalyticsEvent(
          userId,
          session.id,
          'generation_failure',
          { error: error.message }
        );
      }
      
      throw error;
    }
  }
  
  /**
   * Process image content using AI vision
   */
  async processImageContent(contentSource) {
    try {
      logger.info('Processing image content');
      
      // Check cache first
      const contentHash = this.generateContentHash(contentSource.content);
      const cachedAnalysis = await aiGenerationDB.getCachedContentAnalysis(contentHash);
      
      if (cachedAnalysis) {
        logger.info('Using cached image analysis');
        return cachedAnalysis;
      }
      
      // Analyze image with AI
      const analysisPrompt = `Analyze this educational image and extract key learning concepts, topics, and any text content. 
      Focus on identifying educational material that can be used to create flashcards.`;
      
      const analysisResult = await analyzeImageWithPrompt(
        contentSource.content,
        {
          analysisType: 'educational_content',
          subject: contentSource.metadata?.subject,
          difficulty: contentSource.metadata?.difficulty
        }
      );
      
      const extractedContent = {
        text: analysisResult,
        contentType: 'image',
        metadata: contentSource.metadata,
        concepts: this.extractConceptsFromText(analysisResult)
      };
      
      // Cache the result
      await aiGenerationDB.cacheContentAnalysis(
        contentHash,
        'image',
        extractedContent,
        24 // 24 hours TTL
      );
      
      return extractedContent;
      
    } catch (error) {
      logger.error('Image content processing failed:', error);
      throw new Error(`Failed to process image content: ${error.message}`);
    }
  }
  
  /**
   * Process PDF content
   */
  async processPDFContent(contentSource) {
    try {
      logger.info('Processing PDF content');
      
      // For now, assume PDF text is already extracted and provided in content
      // In a full implementation, you would use PDF parsing libraries
      const extractedContent = {
        text: contentSource.content,
        contentType: 'pdf',
        metadata: contentSource.metadata,
        concepts: this.extractConceptsFromText(contentSource.content)
      };
      
      return extractedContent;
      
    } catch (error) {
      logger.error('PDF content processing failed:', error);
      throw new Error(`Failed to process PDF content: ${error.message}`);
    }
  }
  
  /**
   * Process plain text content
   */
  async processTextContent(contentSource) {
    try {
      logger.info('Processing text content');
      
      const extractedContent = {
        text: contentSource.content,
        contentType: 'text',
        metadata: contentSource.metadata,
        concepts: this.extractConceptsFromText(contentSource.content)
      };
      
      return extractedContent;
      
    } catch (error) {
      logger.error('Text content processing failed:', error);
      throw new Error(`Failed to process text content: ${error.message}`);
    }
  }
  
  /**
   * Process topic-based content generation
   */
  async processTopicContent(contentSource) {
    try {
      logger.info(`Processing topic content: ${contentSource.content}`);
      
      // Generate contextual content for the topic
      const topicPrompt = `Generate comprehensive educational content about the topic: "${contentSource.content}". 
      Include key concepts, definitions, important facts, and relationships that would be suitable for creating flashcards.`;
      
      const generatedContent = await generateText(
        topicPrompt,
        'concept_explanation',
        'medium',
        { topic: contentSource.content }
      );
      
      const extractedContent = {
        text: generatedContent,
        contentType: 'topic',
        metadata: contentSource.metadata,
        concepts: this.extractConceptsFromText(generatedContent)
      };
      
      return extractedContent;
      
    } catch (error) {
      logger.error('Topic content processing failed:', error);
      throw new Error(`Failed to process topic content: ${error.message}`);
    }
  }
  
  /**
   * Validate extracted content
   */
  validateContent(extractedContent) {
    const errors = [];
    const warnings = [];
    
    // Check if content has sufficient text
    if (!extractedContent.text || extractedContent.text.trim().length < 50) {
      errors.push('Content is too short to generate meaningful flashcards');
    }
    
    // Check if concepts were extracted
    if (!extractedContent.concepts || extractedContent.concepts.length === 0) {
      warnings.push('No clear concepts identified in content');
    }
    
    // Check content type
    if (!['image', 'pdf', 'text', 'topic'].includes(extractedContent.contentType)) {
      errors.push('Invalid content type');
    }
    
    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }
  
  /**
   * Analyze content to extract learning concepts
   */
  async analyzeContent(extractedContent) {
    try {
      logger.info('Analyzing content for learning concepts');
      
      const analysisPrompt = `Analyze the following educational content and provide a structured analysis:
      
      Content: ${extractedContent.text}
      
      Please identify:
      1. Key topics and concepts
      2. Learning objectives
      3. Estimated difficulty level (beginner/intermediate/advanced)
      4. Subject area
      5. Concept importance weights (0-1 scale)
      
      Return the analysis in JSON format.`;
      
      const analysisResult = await generateText(
        analysisPrompt,
        'detailed_analysis',
        'high'
      );
      
      // Parse AI response (simplified - in production, you'd have more robust parsing)
      let parsedAnalysis;
      try {
        // Clean and parse JSON response
        const cleanedResponse = analysisResult.replace(/```json|```/g, '').trim();
        parsedAnalysis = JSON.parse(cleanedResponse);
      } catch (parseError) {
        // Fallback to basic analysis
        parsedAnalysis = {
          keyTopics: extractedContent.concepts.slice(0, 5),
          learningObjectives: [`Understand key concepts in ${extractedContent.contentType} content`],
          estimatedDifficulty: 'intermediate',
          subjectArea: 'General',
          conceptWeights: {}
        };
      }
      
      return {
        id: crypto.randomUUID(),
        keyTopics: parsedAnalysis.keyTopics || extractedContent.concepts.slice(0, 5),
        learningObjectives: parsedAnalysis.learningObjectives || [],
        estimatedDifficulty: parsedAnalysis.estimatedDifficulty || 'intermediate',
        subjectArea: parsedAnalysis.subjectArea || 'General',
        conceptWeights: parsedAnalysis.conceptWeights || {},
        analyzedAt: new Date()
      };
      
    } catch (error) {
      logger.error('Content analysis failed:', error);
      throw new Error(`Failed to analyze content: ${error.message}`);
    }
  }
  
  /**
   * Generate flashcards from content analysis
   */
  async generateFlashcardsFromAnalysis(analysis, options) {
    try {
      logger.info(`Generating ${options.count} flashcards from analysis`);
      
      // Build context for flashcard generation
      const context = `
      Subject: ${analysis.subjectArea}
      Key Topics: ${analysis.keyTopics.join(', ')}
      Learning Objectives: ${analysis.learningObjectives.join(', ')}
      Difficulty Level: ${options.difficulty}
      `;
      
      // Generate flashcards using existing service
      const aiResponse = await generateFlashcards(
        analysis.keyTopics.join(', '),
        options.count,
        options.difficulty,
        {
          context,
          tags: options.subjects,
          focusAreas: options.focusAreas
        }
      );
      
      // Parse and structure the response
      const flashcards = this.parseFlashcardResponse(aiResponse, analysis);
      
      return flashcards;
      
    } catch (error) {
      logger.error('Flashcard generation from analysis failed:', error);
      throw new Error(`Failed to generate flashcards: ${error.message}`);
    }
  }
  
  /**
   * Parse AI flashcard response into structured format
   */
  parseFlashcardResponse(aiResponse, analysis) {
    try {
      // Clean and parse JSON response
      let cleanedResponse = aiResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.replace(/^```json\s*/, '').replace(/\s*```$/, '');
      }
      
      const parsedResponse = JSON.parse(cleanedResponse);
      
      if (parsedResponse.flashcards && Array.isArray(parsedResponse.flashcards)) {
        return parsedResponse.flashcards.map(card => ({
          id: crypto.randomUUID(),
          question: card.question,
          answer: card.answer,
          difficulty: card.difficulty || analysis.estimatedDifficulty,
          subject: card.category || analysis.subjectArea,
          concepts: card.tags || analysis.keyTopics.slice(0, 3),
          confidence: 0.8, // Default confidence
          explanation: card.explanation,
          memoryTip: card.memory_tip,
          generatedAt: new Date()
        }));
      }
      
      throw new Error('Invalid flashcard response format');
      
    } catch (error) {
      logger.error('Failed to parse flashcard response:', error);
      throw new Error(`Failed to parse AI response: ${error.message}`);
    }
  }
  
  /**
   * Assess quality of generated flashcards
   */
  async assessFlashcardQuality(flashcards) {
    try {
      logger.info(`Assessing quality of ${flashcards.length} flashcards`);
      
      const assessedFlashcards = [];
      
      for (const flashcard of flashcards) {
        // Basic quality assessment (in production, you might use AI for this too)
        const qualityScore = this.calculateBasicQualityScore(flashcard);
        
        assessedFlashcards.push({
          ...flashcard,
          qualityScore,
          confidence: Math.min(flashcard.confidence * qualityScore.overall, 1.0)
        });
      }
      
      return assessedFlashcards;
      
    } catch (error) {
      logger.error('Quality assessment failed:', error);
      throw new Error(`Failed to assess flashcard quality: ${error.message}`);
    }
  }
  
  /**
   * Calculate basic quality score for a flashcard
   */
  calculateBasicQualityScore(flashcard) {
    let clarity = 0.8;
    let accuracy = 0.8;
    let difficulty = 0.8;
    let relevance = 0.8;
    const feedback = [];
    
    // Check question length and clarity
    if (flashcard.question.length < 10) {
      clarity -= 0.2;
      feedback.push('Question is too short');
    }
    if (flashcard.question.length > 200) {
      clarity -= 0.1;
      feedback.push('Question is quite long');
    }
    
    // Check answer completeness
    if (flashcard.answer.length < 5) {
      accuracy -= 0.3;
      feedback.push('Answer is too brief');
    }
    
    // Check for question marks in questions
    if (!flashcard.question.includes('?') && !flashcard.question.toLowerCase().includes('what') && 
        !flashcard.question.toLowerCase().includes('how') && !flashcard.question.toLowerCase().includes('why')) {
      clarity -= 0.1;
      feedback.push('Question format could be clearer');
    }
    
    const overall = (clarity + accuracy + difficulty + relevance) / 4;
    
    return {
      overall: Math.max(0, overall),
      clarity: Math.max(0, clarity),
      accuracy: Math.max(0, accuracy),
      difficulty: Math.max(0, difficulty),
      relevance: Math.max(0, relevance),
      feedback
    };
  }
  
  // Utility Methods
  
  /**
   * Generate content hash for caching
   */
  generateContentHash(content) {
    return crypto.createHash('sha256').update(content).digest('hex');
  }
  
  /**
   * Extract concepts from text using simple keyword extraction
   */
  extractConceptsFromText(text) {
    // Simple concept extraction - in production, you might use NLP libraries
    const words = text.toLowerCase().match(/\b\w{4,}\b/g) || [];
    const wordFreq = {};
    
    words.forEach(word => {
      wordFreq[word] = (wordFreq[word] || 0) + 1;
    });
    
    // Get top concepts by frequency
    return Object.entries(wordFreq)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([word]) => word);
  }
  
  /**
   * Calculate average confidence of flashcards
   */
  calculateAverageConfidence(flashcards) {
    if (flashcards.length === 0) return 0;
    
    const totalConfidence = flashcards.reduce((sum, card) => sum + (card.confidence || 0), 0);
    return totalConfidence / flashcards.length;
  }
  
  /**
   * Get service health status
   */
  async getHealthStatus() {
    try {
      const dbHealth = await aiGenerationDB.getHealthStatus();
      
      return {
        status: dbHealth.status === 'healthy' ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        components: {
          database: dbHealth.status,
          aiService: 'healthy' // Would check Vertex AI connectivity in production
        }
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

module.exports = new AIGenerationService();