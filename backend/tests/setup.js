// Setup para tests
const mongoose = require('mongoose');

// Configurar variables de entorno para tests
process.env.NODE_ENV = 'test';
process.env.MONGO_URI = 'mongodb://localhost:27017/enruta_test';
process.env.REDIS_URL = 'redis://localhost:6379';

// Mock de Redis para tests
jest.mock('../shared/cache', () => ({
  cache: {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn()
  }
}));

// Mock de DB para tests
jest.mock('../shared/db', () => ({
  connectDB: jest.fn(),
  mongoose: {
    connection: {
      db: {
        admin: () => ({
          ping: jest.fn().mockResolvedValue(true)
        })
      }
    }
  }
}));

// Mock de logger
jest.mock('../shared/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn()
}));

// Limpiar mocks después de cada test
afterEach(() => {
  jest.clearAllMocks();
});