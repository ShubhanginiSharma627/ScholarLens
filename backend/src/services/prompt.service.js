const fs = require('fs').promises;
const path = require('path');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/prompt-service.log' })
  ]
});

// Prompt types and their corresponding files
const PROMPT_TYPES = {
  EXPLANATION: 'explanation.prompts.txt',
  REVISION_PLAN: 'revisionplan.prompts.txt',
  FLASHCARD_GENERATION: 'flashcard_generation.prompts.txt',
  IMAGE_ANALYSIS: 'image_analysis.prompts.txt',
  STUDY_PLANNING: 'study_planning.prompts.txt',
  TUTOR_CHAT: 'tutor_chat.prompts.txt',
  SYLLABUS_ANALYSIS: 'syllabus_analysis.prompts.txt'
};

// Cache for loaded prompts
const promptCache = new Map();

// Base prompts directory - use absolute path from the project root
const PROMPTS_DIR = path.resolve(__dirname, '..', '..', 'prompts');

/**
 * Load a prompt template from file
 * @param {string} promptType - Type of prompt to load
 * @returns {Promise<string>} - The prompt template content
 */
async function loadPrompt(promptType) {
  try {
    // Check cache first
    if (promptCache.has(promptType)) {
      logger.debug(`Loading prompt from cache: ${promptType}`);
      return promptCache.get(promptType);
    }

    // Validate prompt type
    if (!PROMPT_TYPES[promptType]) {
      throw new Error(`Unknown prompt type: ${promptType}`);
    }

    const filename = PROMPT_TYPES[promptType];
    const filePath = path.join(PROMPTS_DIR, filename);

    // Check if file exists
    try {
      await fs.access(filePath);
    } catch (error) {
      throw new Error(`Prompt file not found: ${filename}`);
    }

    // Load prompt content
    const promptContent = await fs.readFile(filePath, 'utf8');
    
    // Cache the prompt
    promptCache.set(promptType, promptContent);
    
    logger.info(`Loaded prompt template: ${promptType}`);
    return promptContent;

  } catch (error) {
    logger.error(`Failed to load prompt ${promptType}:`, error.message);
    throw error;
  }
}

/**
 * Build a complete prompt by combining template with user input
 * @param {string} promptType - Type of prompt template
 * @param {object} parameters - Parameters to inject into the prompt
 * @returns {Promise<string>} - Complete prompt ready for AI
 */
async function buildPrompt(promptType, parameters = {}) {
  try {
    const template = await loadPrompt(promptType);
    
    // For now, we'll append parameters as context
    // In the future, we could implement template variable substitution
    let prompt = template;
    
    if (Object.keys(parameters).length > 0) {
      prompt += '\n\n────────────────────────────\nINPUT PARAMETERS\n────────────────────────────\n';
      
      for (const [key, value] of Object.entries(parameters)) {
        if (value !== null && value !== undefined) {
          prompt += `${key}: ${JSON.stringify(value)}\n`;
        }
      }
    }
    
    logger.debug(`Built prompt for type: ${promptType}`);
    return prompt;

  } catch (error) {
    logger.error(`Failed to build prompt ${promptType}:`, error.message);
    throw error;
  }
}

/**
 * Get explanation prompt with parameters
 * @param {object} params - Explanation parameters
 * @returns {Promise<string>} - Complete explanation prompt
 */
async function getExplanationPrompt(params = {}) {
  const {
    topic,
    audience = 'student',
    type = 'detailed',
    syllabus_context,
    variation
  } = params;

  return await buildPrompt('EXPLANATION', {
    topic,
    audience,
    type,
    syllabus_context,
    variation
  });
}

/**
 * Get revision plan prompt with parameters
 * @param {object} params - Revision plan parameters
 * @returns {Promise<string>} - Complete revision plan prompt
 */
async function getRevisionPlanPrompt(params = {}) {
  const {
    topic,
    audience = 'student',
    length = 'comprehensive',
    constraints
  } = params;

  return await buildPrompt('REVISION_PLAN', {
    topic,
    audience,
    length,
    constraints
  });
}

/**
 * Get flashcard generation prompt with parameters
 * @param {object} params - Flashcard generation parameters
 * @returns {Promise<string>} - Complete flashcard prompt
 */
async function getFlashcardPrompt(params = {}) {
  const {
    topic,
    count = 5,
    difficulty = 'medium',
    context,
    tags
  } = params;

  return await buildPrompt('FLASHCARD_GENERATION', {
    topic,
    count,
    difficulty,
    context,
    tags
  });
}

/**
 * Get image analysis prompt with parameters
 * @param {object} params - Image analysis parameters
 * @returns {Promise<string>} - Complete image analysis prompt
 */
async function getImageAnalysisPrompt(params = {}) {
  const {
    analysis_type = 'general',
    subject,
    language = 'English',
    difficulty
  } = params;

  return await buildPrompt('IMAGE_ANALYSIS', {
    analysis_type,
    subject,
    language,
    difficulty
  });
}

/**
 * Get study planning prompt with parameters
 * @param {object} params - Study planning parameters
 * @returns {Promise<string>} - Complete study planning prompt
 */
async function getStudyPlanningPrompt(params = {}) {
  const {
    subjects,
    exam_dates,
    available_time,
    current_level = 'intermediate',
    study_preferences,
    goals,
    constraints
  } = params;

  return await buildPrompt('STUDY_PLANNING', {
    subjects,
    exam_dates,
    available_time,
    current_level,
    study_preferences,
    goals,
    constraints
  });
}

/**
 * Get tutor chat prompt with parameters
 * @param {object} params - Tutor chat parameters
 * @returns {Promise<string>} - Complete tutor chat prompt
 */
async function getTutorChatPrompt(params = {}) {
  const {
    message,
    subject,
    student_level,
    conversation_history,
    learning_goals,
    session_type = 'general_chat'
  } = params;

  return await buildPrompt('TUTOR_CHAT', {
    message,
    subject,
    student_level,
    conversation_history,
    learning_goals,
    session_type
  });
}

/**
 * Get syllabus analysis prompt with parameters
 * @param {object} params - Syllabus analysis parameters
 * @returns {Promise<string>} - Complete syllabus analysis prompt
 */
async function getSyllabusAnalysisPrompt(params = {}) {
  const {
    syllabus_content,
    course_level,
    subject_area,
    analysis_type = 'structure_extraction',
    semester_length
  } = params;

  return await buildPrompt('SYLLABUS_ANALYSIS', {
    syllabus_content,
    course_level,
    subject_area,
    analysis_type,
    semester_length
  });
}

/**
 * Get all available prompt types
 * @returns {object} - Available prompt types and their descriptions
 */
function getAvailablePrompts() {
  return {
    EXPLANATION: {
      file: PROMPT_TYPES.EXPLANATION,
      description: 'Generate educational explanations for topics',
      parameters: ['topic', 'audience', 'type', 'syllabus_context', 'variation']
    },
    REVISION_PLAN: {
      file: PROMPT_TYPES.REVISION_PLAN,
      description: 'Create structured revision and study plans',
      parameters: ['topic', 'audience', 'length', 'constraints']
    },
    FLASHCARD_GENERATION: {
      file: PROMPT_TYPES.FLASHCARD_GENERATION,
      description: 'Generate educational flashcards for topics',
      parameters: ['topic', 'count', 'difficulty', 'context', 'tags']
    },
    IMAGE_ANALYSIS: {
      file: PROMPT_TYPES.IMAGE_ANALYSIS,
      description: 'Analyze educational content from images',
      parameters: ['analysis_type', 'subject', 'language', 'difficulty']
    },
    STUDY_PLANNING: {
      file: PROMPT_TYPES.STUDY_PLANNING,
      description: 'Create comprehensive study plans and schedules',
      parameters: ['subjects', 'exam_dates', 'available_time', 'current_level', 'study_preferences', 'goals', 'constraints']
    },
    TUTOR_CHAT: {
      file: PROMPT_TYPES.TUTOR_CHAT,
      description: 'Provide tutoring and educational chat responses',
      parameters: ['message', 'subject', 'student_level', 'conversation_history', 'learning_goals', 'session_type']
    },
    SYLLABUS_ANALYSIS: {
      file: PROMPT_TYPES.SYLLABUS_ANALYSIS,
      description: 'Analyze academic syllabi and course documents',
      parameters: ['syllabus_content', 'course_level', 'subject_area', 'analysis_type', 'semester_length']
    }
  };
}

/**
 * Clear prompt cache (useful for development/testing)
 */
function clearCache() {
  promptCache.clear();
  logger.info('Prompt cache cleared');
}

/**
 * Reload a specific prompt from file (bypassing cache)
 * @param {string} promptType - Type of prompt to reload
 * @returns {Promise<string>} - The reloaded prompt content
 */
async function reloadPrompt(promptType) {
  // Remove from cache
  promptCache.delete(promptType);
  
  // Load fresh from file
  return await loadPrompt(promptType);
}

/**
 * Validate prompt parameters
 * @param {string} promptType - Type of prompt
 * @param {object} parameters - Parameters to validate
 * @returns {object} - Validation result
 */
function validateParameters(promptType, parameters) {
  const availablePrompts = getAvailablePrompts();
  const promptInfo = availablePrompts[promptType];
  
  if (!promptInfo) {
    return {
      valid: false,
      error: `Unknown prompt type: ${promptType}`
    };
  }
  
  const requiredParams = promptInfo.parameters || [];
  const providedParams = Object.keys(parameters);
  
  // For now, we'll just log the parameters - in the future we could add strict validation
  logger.debug(`Validating parameters for ${promptType}:`, {
    required: requiredParams,
    provided: providedParams
  });
  
  return {
    valid: true,
    promptType,
    parameters
  };
}

module.exports = {
  loadPrompt,
  buildPrompt,
  getExplanationPrompt,
  getRevisionPlanPrompt,
  getFlashcardPrompt,
  getImageAnalysisPrompt,
  getStudyPlanningPrompt,
  getTutorChatPrompt,
  getSyllabusAnalysisPrompt,
  getAvailablePrompts,
  clearCache,
  reloadPrompt,
  validateParameters,
  PROMPT_TYPES
};