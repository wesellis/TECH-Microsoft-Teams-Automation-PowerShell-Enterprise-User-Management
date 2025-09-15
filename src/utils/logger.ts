import winston from 'winston';
import path from 'path';

const logDir = process.env.LOG_DIR || 'logs';

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, ...metadata }) => {
    let msg = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    if (Object.keys(metadata).length > 0) {
      msg += ` ${JSON.stringify(metadata)}`;
    }
    return msg;
  })
);

// Create logger instance
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports: [
    // Console transport
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(logDir, 'app.log'),
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    // File transport for errors
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    })
  ],
  // Handle exceptions and rejections
  exceptionHandlers: [
    new winston.transports.File({ 
      filename: path.join(logDir, 'exceptions.log') 
    })
  ],
  rejectionHandlers: [
    new winston.transports.File({ 
      filename: path.join(logDir, 'rejections.log') 
    })
  ]
});

// Export additional logging utilities
export const loggers = {
  performance: winston.createLogger({
    level: 'info',
    format: logFormat,
    transports: [
      new winston.transports.File({
        filename: path.join(logDir, 'performance.log'),
        maxsize: 10485760,
        maxFiles: 3
      })
    ]
  }),
  
  security: winston.createLogger({
    level: 'info',
    format: logFormat,
    transports: [
      new winston.transports.File({
        filename: path.join(logDir, 'security.log'),
        maxsize: 10485760,
        maxFiles: 5
      })
    ]
  }),
  
  audit: winston.createLogger({
    level: 'info',
    format: logFormat,
    transports: [
      new winston.transports.File({
        filename: path.join(logDir, 'audit.log'),
        maxsize: 10485760,
        maxFiles: 10
      })
    ]
  })
};