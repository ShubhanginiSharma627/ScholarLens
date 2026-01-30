const winston = require('winston');
const path = require('path');
const fs = require('fs-extra');
const logsDir = path.join(__dirname, '../../logs');
fs.ensureDirSync(logsDir);
const customFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss.SSS'
  }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}] ${message}`;
    if (Object.keys(meta).length > 0) {
      log += `\n${JSON.stringify(meta, null, 2)}`;
    }
    return log;
  })
);
const jsonFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);
const createLogger = (service, level = 'info') => {
  return winston.createLogger({
    level: process.env.LOG_LEVEL || level,
    format: jsonFormat,
    defaultMeta: { service },
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          customFormat
        )
      }),
      new winston.transports.File({
        filename: path.join(logsDir, `${service}.log`),
        format: jsonFormat
      }),
      new winston.transports.File({
        filename: path.join(logsDir, `${service}-error.log`),
        level: 'error',
        format: jsonFormat
      }),
      new winston.transports.File({
        filename: path.join(logsDir, 'combined.log'),
        format: jsonFormat
      })
    ],
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
const logPerformance = (operation, duration, metadata = {}) => {
  performanceLogger.info('Performance metric', {
    operation,
    duration,
    ...metadata,
    timestamp: new Date().toISOString()
  });
  if (duration > 5000) { // 5 seconds
    performanceLogger.warn('Slow operation detected', {
      operation,
      duration,
      ...metadata
    });
  }
};
const logSecurity = (event, details = {}) => {
  securityLogger.info('Security event', {
    event,
    ...details,
    timestamp: new Date().toISOString()
  });
};
const logBusiness = (event, userId, details = {}) => {
  businessLogger.info('Business event', {
    event,
    userId,
    ...details,
    timestamp: new Date().toISOString()
  });
};
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