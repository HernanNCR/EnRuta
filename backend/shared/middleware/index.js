const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const logger = require('../logger');

const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
};

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});

const requestLogger = (req, res, next) => {
  logger.info(`${req.method} ${req.url}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
};

const errorHandler = (err, req, res, next) => {
  logger.error('Error occurred:', err);
  res.status(500).json({ error: 'Internal server error' });
};

module.exports = {
  corsOptions,
  limiter,
  requestLogger,
  errorHandler,
  cors: cors(corsOptions),
  helmet: helmet(),
};