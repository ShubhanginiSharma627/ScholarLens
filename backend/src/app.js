require('dotenv').config();
require('express-async-errors');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const fs = require('fs-extra');
const path = require('path');
const authRoutes = require('./routes/auth.routes');
const flashcardRoutes = require('./routes/flashcard.routes');
const aiRoutes = require('./routes/ai.routes');
const enhancedAiRoutes = require('./routes/enhanced-ai.routes');
const aiGenerationRoutes = require('./routes/ai-generation.routes');
const planRoutes = require('./routes/plan.routes');
const explainRoutes = require('./routes/explain.routes');
const syllabusRoutes = require('./routes/syllabus.routes');
const examRoutes = require('./routes/exam.routes');
const visionRoutes = require('./routes/vision.routes');
const statsRoutes = require('./routes/stats.routes');
const storageRoutes = require('./routes/storage.routes');
const { createRateLimit } = require('./middleware/auth.middleware');
const { logRequests, logErrors } = require('./middleware/request-logger.middleware');
const { nowIso } = require('./utils/dateUtils');
const app = express();
fs.ensureDirSync('logs');
const gcsStorage = require('./services/gcs-storage.service');
const gcsConfig = gcsStorage.getConfigStatus();
if (gcsConfig.initialized) {
  console.log('✅ Google Cloud Storage initialized successfully');
} else {
  console.warn('⚠️  Google Cloud Storage not properly configured');
  console.warn('   Check GOOGLE_CLOUD_PROJECT and GOOGLE_APPLICATION_CREDENTIALS');
}
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(morgan('combined'));
app.use(logRequests);
const globalRateLimit = createRateLimit(15 * 60 * 1000, 100); // 100 requests per 15 minutes
app.use(globalRateLimit);
app.get('/', (req, res) => res.json({ 
  success: true, 
  message: 'Scholar Lens AI Backend is running', 
  timestamp: nowIso(),
  version: '1.0.0'
}));
app.use('/api/auth', authRoutes);
app.use('/api/flashcards', flashcardRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/enhanced-ai', enhancedAiRoutes);
app.use('/api/ai-generation', aiGenerationRoutes);
app.use('/api/generate-plan', planRoutes);
app.use('/api/explain-topic', explainRoutes);
app.use('/api/syllabi', syllabusRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/vision', visionRoutes);
app.use('/api/syllabus', syllabusRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/storage', storageRoutes);
app.use('/generate-plan', planRoutes);
app.use('/explain-topic', explainRoutes);
app.use('/syllabi', syllabusRoutes);
app.use('/exam', examRoutes);
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    error: { message: 'Endpoint not found' } 
  });
});
app.use(logErrors);
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  const status = err.status || 500;
  const payload = { 
    success: false, 
    error: { message: 'Internal server error' } 
  };
  if (process.env.NODE_ENV !== 'production') {
    payload.error.details = err.message;
    payload.error.stack = err.stack;
  }
  res.status(status).json(payload);
});
const PORT = process.env.PORT || "3000";
app.listen(PORT, () => {
  console.log(`🚀 Scholar Lens Backend listening on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
});
module.exports = app;