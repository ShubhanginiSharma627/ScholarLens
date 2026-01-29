const winston = require('winston');
const path = require('path');
const fs = require('fs-extra');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');
fs.ensureDirSync(logsDir);

// Custom format for better readability
const customFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss.SSS'
  }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}] ${message}`;
    
    // Add metadata if present
    if (Object.keys(meta).length > 0) {
      log += `\n${JSON.stringify(meta, null, 2)}`;
    }
    
    return log;
  })
);

// JSON format for structured logging
const jsonFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Create different loggers for different purposes
const createLogger = (service, level = 'info') => {
  return winston.createLogger({
    level: process.env.LOG_LEVEL || level,
    format: jsonFormat,
    defaultMeta: { service },
    transports: [
      // Console output with custom format
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          customFormat
        )
      }),
      
      // All logs
      new winston.transports.File({
        filename: path.join(logsDir, `${service}.log`),
        format: jsonFormat
      }),
      
      // Error logs only
      new winston.transports.File({
        filename: path.join(logsDir, `${service}-error.log`),
        level: 'error',
        format: jsonFormat
      }),
      
      // Combined logs for all services
      new winston.transports.File({
        filename: path.join(logsDir, 'combined.log'),
        format: jsonFormat
      })
    ],
    
    // Handle exceptions and rejections
    exceptionHandlers: [
      new winston.transports.File({
        filename: path.join(logsDir, `${service}-exceptions.log`)
      })
    ],
    
    rejectionHandlers: [
      new winston.transports.File({
        filename: path.join(logsDir, `${service}-rejections.log`)
      })
    ]
  });
};

// Performance logger for tracking slow operations
const performanceLogger = winston.createLogger({
  level: 'info',
  format: jsonFormat,
  defaultMeta: { service: 'performance' },
  transports: [
    new winston.transports.File({
      filename: path.join(logsDir, 'performance.log'),
      format: jsonFormat
    })
  ]
});

// Security logger for auth and security events
const securityLogger = winston.createLogger({
  level: 'info',
  format: jsonFormat,
  defaultMeta: { service: 'security' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        customFormat
      )
    }),
    new winston.transports.File({
      filename: path.join(logsDir, 'security.log'),
      format: jsonFormat
    })
  ]
});

// Business logic logger for tracking user interactions
const businessLogger = winston.createLogger({
  level: 'info',
  format: jsonFormat,
  defaultMeta: { service: 'business' },
  transports: [
    new winston.transports.File({
      filename: path.join(logsDir, 'business.log'),
      format: jsonFormat
    })
  ]
});

// Helper function to log performance metrics
const logPerformance = (operation, duration, metadata = {}) => {
  performanceLogger.info('Performance metric', {
    operation,
    duration,
    ...metadata,
    timestamp: new Date().toISOString()
  });
  
  // Log warning for slow operations
  if (duration > 5000) { // 5 seconds
    performanceLogger.warn('Slow operation detected', {
      operation,
      duration,
      ...metadata
    });
  }
};

// Helper function to log security events
const logSecurity = (event, details = {}) => {
  securityLogger.info('Security event', {
    event,
    ...details,
    timestamp: new Date().toISOString()
  });
};

// Helper function to log business events
const logBusiness = (event, userId, details = {}) => {
  businessLogger.info('Business event', {
    event,
    userId,
    ...details,
    timestamp: new Date().toISOString()
  });
};

// Log rotation configuration (for production)
const rotatingFileTransport = (filename, options = {}) => {
  return new winston.transports.File({
    filename: path.join(logsDir, filename),
    maxsize: 10 * 1024 * 1024, // 10MB
    maxFiles: 5,
    format: jsonFormat,
    ...options
  });
};

module.exports = {
  createLogger,
  performanceLogger,
  securityLogger,
  businessLogger,
  logPerformance,
  logSecurity,
  logBusiness,
  rotatingFileTransport,
  logsDir
};