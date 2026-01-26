require('dotenv').config();
require('express-async-errors');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const planRoutes = require('./routes/plan.routes');
const explainRoutes = require('./routes/explain.routes');
const syllabusRoutes = require('./routes/syllabus.routes');
const examRoutes = require('./routes/exam.routes');
const visionRoutes = require('./routes/vision.routes');
const statsRoutes = require('./routes/stats.routes');
const { nowIso } = require('./utils/dateUtils');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(morgan('combined'));

app.get('/', (req, res) => res.json({ success: true, message: 'AI Backend is running', timestamp: nowIso() }));

app.use('/generate-plan', planRoutes);
app.use('/explain-topic', explainRoutes);
app.use('/syllabi', syllabusRoutes);
app.use('/exam', examRoutes);
app.use('/api/vision', visionRoutes);
app.use('/api/syllabus', syllabusRoutes);
app.use('/api/stats', statsRoutes);

// 404
app.use((req, res) => {
  res.status(404).json({ success: false, error: { message: 'Not found' } });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  const payload = { success: false, error: { message: 'Internal server error' } };
  if (process.env.NODE_ENV !== 'production') {
    payload.error.details = err.message;
  }
  res.status(status).json(payload);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});

module.exports = app;
