const axios = require('axios');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/scienceqa-service.log' })
  ]
});
const SCIENCEQA_CONFIG = {
  baseUrl: process.env.SCIENCEQA_BASE_URL || 'http://localhost:8000',
  timeout: parseInt(process.env.SCIENCEQA_TIMEOUT) || 10000,
  enabled: process.env.SCIENCEQA_ENABLED !== 'false'
};
logger.info('ScienceQA Configuration:', SCIENCEQA_CONFIG);
async function isServiceAvailable() {
  if (!SCIENCEQA_CONFIG.enabled) {
    return false;
  }
  try {
    const response = await axios.get(`${SCIENCEQA_CONFIG.baseUrl}/`, {
      timeout: 5000
    });
    return response.status === 200 && response.data?.status === 'Online';
  } catch (error) {
    logger.warn('ScienceQA service not available:', error.message);
    return false;
  }
}
async function retrieveContext(query, subject = null) {
  if (!SCIENCEQA_CONFIG.enabled) {
    logger.debug('ScienceQA disabled, skipping context retrieval');
    return null;
  }
  try {
    logger.info(`Retrieving context from ScienceQA for query: "${query.substring(0, 100)}..."`);
    const requestData = {
      question_text: query,
      subject: subject
    };
    const response = await axios.post(
      `${SCIENCEQA_CONFIG.baseUrl}/retrieve`,
      requestData,
      {
        timeout: SCIENCEQA_CONFIG.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    if (response.status === 200 && response.data) {
      const { answer_context, source_topic, confidence_score } = response.data;
      if (answer_context && 
          answer_context.length > 50 && 
          !answer_context.includes('No relevant textbook info found') &&
          confidence_score > 0.7) {
        logger.info(`ScienceQA context retrieved successfully. Topic: ${source_topic}, Confidence: ${confidence_score}`);
        return {
          context: answer_context,
          topic: source_topic,
          confidence: confidence_score,
          source: 'scienceqa'
        };
      } else {
        logger.debug('ScienceQA returned low-quality or no context');
        return null;
      }
    }
    return null;
  } catch (error) {
    logger.error('Error retrieving context from ScienceQA:', error.message);
    return null;
  }
}
async function generateQuiz(topic, difficulty = 'Medium', count = 5) {
  if (!SCIENCEQA_CONFIG.enabled) {
    logger.debug('ScienceQA disabled, skipping quiz generation');
    return null;
  }
  try {
    logger.info(`Generating quiz from ScienceQA for topic: "${topic}", difficulty: ${difficulty}, count: ${count}`);
    const requestData = {
      topic: topic,
      difficulty: difficulty
    };
    const response = await axios.post(
      `${SCIENCEQA_CONFIG.baseUrl}/quiz/generate`,
      requestData,
      {
        timeout: SCIENCEQA_CONFIG.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    if (response.status === 200 && response.data?.quiz) {
      const questions = response.data.quiz;
      if (questions.length > 0) {
        const limitedQuestions = questions.slice(0, count);
        logger.info(`ScienceQA quiz generated successfully. Questions: ${limitedQuestions.length}`);
        return limitedQuestions.map(q => ({
          ...q,
          source: 'scienceqa'
        }));
      }
    }
    logger.debug('ScienceQA returned no quiz questions');
    return null;
  } catch (error) {
    logger.error('Error generating quiz from ScienceQA:', error.message);
    return null;
  }
}
async function analyzePerformance(results) {
  if (!SCIENCEQA_CONFIG.enabled) {
    logger.debug('ScienceQA disabled, skipping performance analysis');
    return null;
  }
  try {
    logger.info(`Analyzing performance with ScienceQA for ${results.length} results`);
    const requestData = {
      results: results
    };
    const response = await axios.post(
      `${SCIENCEQA_CONFIG.baseUrl}/quiz/analyze`,
      requestData,
      {
        timeout: SCIENCEQA_CONFIG.timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    if (response.status === 200 && response.data?.feedback) {
      const feedback = response.data.feedback;
      if (feedback && feedback.length > 10) {
        logger.info('ScienceQA performance analysis completed successfully');
        return feedback;
      }
    }
    logger.debug('ScienceQA returned no performance feedback');
    return null;
  } catch (error) {
    logger.error('Error analyzing performance with ScienceQA:', error.message);
    return null;
  }
}
async function getServiceStatus() {
  const available = await isServiceAvailable();
  return {
    enabled: SCIENCEQA_CONFIG.enabled,
    available: available,
    baseUrl: SCIENCEQA_CONFIG.baseUrl,
    timeout: SCIENCEQA_CONFIG.timeout,
    features: [
      'context_retrieval',
      'quiz_generation', 
      'performance_analysis'
    ]
  };
}
module.exports = {
  retrieveContext,
  generateQuiz,
  analyzePerformance,
  isServiceAvailable,
  getServiceStatus,
  SCIENCEQA_CONFIG
};