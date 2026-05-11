const request = require('supertest');
const express = require('express');

// Mock del controlador de pagos
const mockPagosController = {
  crearPago: jest.fn(),
  obtenerPagosUsuario: jest.fn(),
  procesarPago: jest.fn(),
  reembolsarPago: jest.fn()
};

jest.mock('../services/pagos/controllers/pagosController', () => mockPagosController);

const pagosRoutes = require('../services/pagos/routes');

const app = express();
app.use(express.json());
app.use('/api/pagos', pagosRoutes);

const pagosController = require('../services/pagos/controllers/pagosController');

describe('Pagos API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('POST /api/pagos should create payment', async () => {
    const mockResponse = {
      message: 'Pago creado exitosamente',
      pago: { id: '123', monto: 25.50 }
    };
    pagosController.crearPago.mockImplementation((req, res) => {
      res.status(201).json(mockResponse);
    });

    const paymentData = {
      usuarioId: '507f1f77bcf86cd799439011',
      colectivoId: '507f1f77bcf86cd799439012',
      monto: 25.50,
      metodoPago: 'efectivo'
    };

    const response = await request(app)
      .post('/api/pagos')
      .send(paymentData)
      .expect(201);

    expect(response.body.message).toBe('Pago creado exitosamente');
    expect(response.body).toHaveProperty('pago');
  });

  test('GET /api/pagos/usuario/:usuarioId should return user payments', async () => {
    const mockResponse = {
      pagos: [{ id: '1', monto: 25.50 }],
      pagination: { page: 1, total: 1 }
    };
    pagosController.obtenerPagosUsuario.mockImplementation((req, res) => {
      res.json(mockResponse);
    });

    const response = await request(app)
      .get('/api/pagos/usuario/507f1f77bcf86cd799439011')
      .expect(200);

    expect(response.body).toHaveProperty('pagos');
    expect(response.body).toHaveProperty('pagination');
    expect(Array.isArray(response.body.pagos)).toBe(true);
  });
});