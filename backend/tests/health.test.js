const request = require('supertest');
const express = require('express');

// Mock del servicio de health
jest.mock('../services/health/service', () => ({
  getHealthStatus: jest.fn()
}));

const healthRoutes = require('../services/health/routes');

const app = express();
app.use(express.json());
app.use('/api/health', healthRoutes);

const healthService = require('../services/health/service');

describe('Health API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/health should return health status', async () => {
    const mockHealth = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: { database: { status: 'ok' }, redis: { status: 'ok' } },
      system: { memory: { rss: '50MB' } }
    };
    healthService.getHealthStatus.mockResolvedValue(mockHealth);

    const response = await request(app)
      .get('/api/health')
      .expect(200);

    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('services');
    expect(response.body).toHaveProperty('system');
  });

  test('GET /api/health/detailed should return detailed health', async () => {
    const mockHealth = {
      status: 'healthy',
      uptime: 12345,
      services: { database: { status: 'ok' }, redis: { status: 'ok' } }
    };
    healthService.getHealthStatus.mockResolvedValue(mockHealth);

    const response = await request(app)
      .get('/api/health/detailed')
      .expect(200);

    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('uptime');
    expect(response.body.services).toHaveProperty('database');
    expect(response.body.services).toHaveProperty('redis');
  });
});