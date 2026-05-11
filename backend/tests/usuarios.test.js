const request = require('supertest');
const express = require('express');

// Mock del controlador de usuarios
const mockUsuariosController = {
  crearUsuario: jest.fn(),
  obtenerUsuario: jest.fn(),
  actualizarUsuario: jest.fn(),
  agregarUnidad: jest.fn(),
  obtenerUnidades: jest.fn(),
  listarUsuarios: jest.fn()
};

jest.mock('../services/usuarios/controllers/usuariosController', () => mockUsuariosController);

const usuariosRoutes = require('../services/usuarios/routes');

const app = express();
app.use(express.json());
app.use('/api/usuarios', usuariosRoutes);

const usuariosController = require('../services/usuarios/controllers/usuariosController');

describe('Usuarios API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('POST /api/usuarios should create user', async () => {
    const mockResponse = {
      message: 'Usuario creado exitosamente',
      usuario: { id: '123', email: 'test@example.com' }
    };
    usuariosController.crearUsuario.mockImplementation((req, res) => {
      res.status(201).json(mockResponse);
    });

    const userData = {
      nombre: 'Juan',
      apellido: 'Pérez',
      email: 'juan@example.com',
      tipoUsuario: 'pasajero'
    };

    const response = await request(app)
      .post('/api/usuarios')
      .send(userData)
      .expect(201);

    expect(response.body.message).toBe('Usuario creado exitosamente');
    expect(response.body.usuario).toHaveProperty('id');
  });

  test('GET /api/usuarios should return users list', async () => {
    const mockResponse = {
      usuarios: [{ nombre: 'Juan', email: 'juan@example.com' }],
      pagination: { page: 1, total: 1 }
    };
    usuariosController.listarUsuarios.mockImplementation((req, res) => {
      res.json(mockResponse);
    });

    const response = await request(app)
      .get('/api/usuarios')
      .expect(200);

    expect(response.body).toHaveProperty('usuarios');
    expect(response.body).toHaveProperty('pagination');
    expect(Array.isArray(response.body.usuarios)).toBe(true);
  });
});