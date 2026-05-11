const request = require('supertest');
const express = require('express');

// Mock de los modelos
jest.mock('../models/colectivos', () => ({
  find: jest.fn(),
  distinct: jest.fn(),
  findOne: jest.fn()
}));

jest.mock('../models/rutas', () => ({}));

const colectivosRoutes = require('../services/colectivos/routes');

const app = express();
app.use(express.json());
app.use('/api/colectivos', colectivosRoutes);

const Colectivos = require('../models/colectivos');

describe('Colectivos API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/colectivos/rutas should return routes', async () => {
    Colectivos.distinct.mockResolvedValue([1, 2, 3]);

    const response = await request(app)
      .get('/api/colectivos/rutas')
      .expect(200);

    expect(Array.isArray(response.body)).toBe(true);
    expect(Colectivos.distinct).toHaveBeenCalledWith("rute");
  });

  test('GET /api/colectivos should return colectivos', async () => {
    const mockColectivos = [
      { numero_economico: 1, rute: 1 },
      { numero_economico: 2, rute: 2 }
    ];
    Colectivos.find.mockReturnValue({
      sort: jest.fn().mockResolvedValue(mockColectivos)
    });

    const response = await request(app)
      .get('/api/colectivos')
      .expect(200);

    expect(Array.isArray(response.body)).toBe(true);
  });

  test('GET /api/colectivos/ruta/:rute should return colectivos for route', async () => {
    const mockColectivos = [{ numero_economico: 1, rute: 1 }];
    Colectivos.find.mockResolvedValue(mockColectivos);

    const response = await request(app)
      .get('/api/colectivos/ruta/1')
      .expect(200);

    expect(Array.isArray(response.body)).toBe(true);
    expect(Colectivos.find).toHaveBeenCalledWith({ rute: "1" });
  });
});