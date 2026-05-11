const request = require('supertest');
const express = require('express');

jest.mock('../models/paradas', () => ({
  create: jest.fn(),
  find: jest.fn(),
}));

const paradasRoutes = require('../routes/colectivos_rutas');
const Paradas = require('../models/paradas');

const app = express();
app.use(express.json());
app.use('/api/ColectivosRutas', paradasRoutes);

describe('Paradas API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('POST /api/ColectivosRutas/guardar-parada should save a stop', async () => {
    const mockParada = {
      _id: '123',
      nombre: 'Parada Centro',
      ubicacion: { lat: '16.75', lng: '-93.12' },
      rutas: [1, 2],
    };
    Paradas.create.mockResolvedValue(mockParada);

    const response = await request(app)
      .post('/api/ColectivosRutas/guardar-parada')
      .send({
        lat: 16.75,
        lng: -93.12,
        nombre: 'Parada Centro',
        rutas: [1, 2],
      })
      .expect(200);

    expect(response.body.message).toBe('Parada guardada correctamente');
    expect(Paradas.create).toHaveBeenCalled();
  });

  test('GET /api/ColectivosRutas/paradas should return all stops', async () => {
    const mockParadas = [
      { nombre: 'Parada 1', ubicacion: { lat: '16.75', lng: '-93.12' }, rutas: [1] },
    ];
    Paradas.find.mockResolvedValue(mockParadas);

    const response = await request(app)
      .get('/api/ColectivosRutas/paradas')
      .expect(200);

    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body[0].nombre).toBe('Parada 1');
  });
});
