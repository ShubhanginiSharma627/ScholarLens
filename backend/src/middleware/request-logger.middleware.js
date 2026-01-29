const winston = require('winston');

// Configure request logger
const requestLogger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/requests.log' })
  ]
});

/**
 * Request logging middleware
 * Logs all incoming HTTP requests with detailed information
 */
const logRequests = (req, res, next) => {
  const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const startTime = Date.now();
  
  // Add request ID to request object for use in other middleware/controllers
  req.requestId = requestId;
  
  // Log incoming request
  requestLogger.info(`[${requestId}] Incoming request`, {
    method: req.method,
    url: req.url,
    path: req.path,
    query: req.query,
    headers: {
      'user-agent': req.headers['user-agent'],
      'content-type': req.headers['content-type'],
      'content-length': req.headers['content-length'],
      'authorization': req.headers.authorization ? 'Bearer [REDACTED]' : undefined,
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'x-real-ip': req.headers['x-real-ip']
    },
    ip: req.ip,
    body: req.method === 'POST' || req.method === 'PUT' ? {
      ...req.body,
      // Redact sensitive fields
      password: req.body?.password ? '[REDACTED]' : undefined,
      token: req.body?.token ? '[REDACTED]' : undefined,
      apiKey: req.body?.apiKey ? '[REDACTED]' : undefined
    } : undefined,
    timestamp: new Date().toISOString()
  });

  // Override res.json to log response
  const originalJson = res.json;
  res.json = function(body) {
    const duration = Date.now() - startTime;
    
    requestLogger.info(`[${requestId}] Response sent`, {
      statusCode: res.statusCode,
      duration,
      responseSize: JSON.stringify(body).length,
      success: body?.success,
      error: body?.error?.message,
      timestamp: new Date().toISOString()
    });
    
    return originalJson.call(this, body);
  };

  // Override res.status to capture status changes
  const originalStatus = res.status;
  res.status = function(code) {
    if (code >= 400) {
      requestLogger.warn(`[${requestId}] Error status set: ${code}`);
    }
    return originalStatus.call(this, code);
  };

  // Log when request finishes (for non-JSON responses)
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    if (!res.headersSent || res.statusCode >= 400) {
      requestLogger.info(`[${requestId}] Request finished`, {
        statusCode: res.statusCode,
        duration,
        timestamp: new Date().toISOString()
      });
    }
  });

  // Log errors
  res.on('error', (error) => {
    const duration = Date.now() - startTime;
    
    requestLogger.error(`[${requestId}] Response error`, {
      error: error.message,
      stack: error.stack,
      duration,
      timestamp: new Date().toISOString()
    });
  });

  next();
};

/**
 * Error logging middleware
 * Logs unhandled errors in the request pipeline
 */
const logErrors = (error, req, res, next) => {
  const requestId = req.requestId || 'unknown';
  
  requestLogger.error(`[${requestId}] Unhandled error`, {
    error: error.message,
    stack: error.stack,
    method: req.method,
    url: req.url,
    headers: req.headers,
    body: req.body,
    timestamp: new Date().toISOString()
  });

  // Don't expose internal errors to client
  if (!res.headersSent) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Internal server error',
        code: 'INTERNAL_ERROR',
        requestId
      }
    });
  }
  
  next(error);
};

module.exports = {
  logRequests,
  logErrors,
  requestLogger
};