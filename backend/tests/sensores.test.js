const request = require('supertest');
const express = require('express');

// Mock del sensor manager
jest.mock('../services/sensores/manager', () => ({
  listSensors: jest.fn(),
  startSensor: jest.fn(),
  stopSensor: jest.fn(),
  activeProcesses: new Map()
}));

const sensoresRoutes = require('../services/sensores/routes');

const app = express();
app.use(express.json());
app.use('/api/sensores', sensoresRoutes);

const sensorManager = require('../services/sensores/manager');

describe('Sensores API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/sensores should return sensors list', async () => {
    sensorManager.listSensors.mockReturnValue(['simulador', 'gps']);
    sensorManager.activeProcesses = new Map([['simulador', {}]]);

    const response = await request(app)
      .get('/api/sensores')
      .expect(200);

    expect(response.body).toHaveProperty('sensors');
    expect(response.body).toHaveProperty('active');
    expect(Array.isArray(response.body.sensors)).toBe(true);
  });

  test('POST /api/sensores/:type/start should start simulator', async () => {
    sensorManager.startSensor.mockResolvedValue({});

    const response = await request(app)
      .post('/api/sensores/simulador/start')
      .expect(200);

    expect(response.body.message).toBe('Sensor simulador started');
    expect(sensorManager.startSensor).toHaveBeenCalledWith('simulador');
  });

  test('POST /api/sensores/:type/stop should stop simulator', async () => {
    sensorManager.stopSensor.mockReturnValue();

    const response = await request(app)
      .post('/api/sensores/simulador/stop')
      .expect(200);

    expect(response.body.message).toBe('Sensor simulador stopped');
    expect(sensorManager.stopSensor).toHaveBeenCalledWith('simulador');
  });
});