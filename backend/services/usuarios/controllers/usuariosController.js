const Usuario = require("./Usuario");
const Sesion = require("./Sesion");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

class UsuariosController {
  // Crear nuevo usuario
  async crearUsuario(req, res) {
    try {
      const { nombre, apellido, email, telefono, tipoUsuario, unidades } = req.body;

      // Verificar si el email ya existe
      const usuarioExistente = await Usuario.findOne({ email });
      if (usuarioExistente) {
        return res.status(400).json({ error: 'El email ya está registrado' });
      }

      // Crear usuario
      const nuevoUsuario = new Usuario({
        nombre,
        apellido,
        email,
        telefono,
        tipoUsuario: tipoUsuario || 'pasajero',
        unidades: unidades || []
      });

      await nuevoUsuario.save();

      res.status(201).json({
        message: 'Usuario creado exitosamente',
        usuario: {
          id: nuevoUsuario._id,
          nombre: nuevoUsuario.nombre,
          apellido: nuevoUsuario.apellido,
          email: nuevoUsuario.email,
          tipoUsuario: nuevoUsuario.tipoUsuario
        }
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Obtener usuario por ID
  async obtenerUsuario(req, res) {
    try {
      const { id } = req.params;
      const usuario = await Usuario.findById(id);

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      res.json({
        usuario: {
          id: usuario._id,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          email: usuario.email,
          tipoUsuario: usuario.tipoUsuario,
          unidades: usuario.unidades,
          activo: usuario.activo,
          ultimoAcceso: usuario.ultimoAcceso
        }
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Actualizar usuario
  async actualizarUsuario(req, res) {
    try {
      const { id } = req.params;
      const updates = req.body;

      // Campos que no se pueden actualizar directamente
      delete updates.email;
      delete updates._id;

      const usuario = await Usuario.findByIdAndUpdate(
        id,
        updates,
        { new: true, runValidators: true }
      );

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      res.json({
        message: 'Usuario actualizado',
        usuario
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Agregar unidad a dueño
  async agregarUnidad(req, res) {
    try {
      const { id } = req.params;
      const { numeroEconomico, placa, modelo, capacidad, rutaAsignada } = req.body;

      const usuario = await Usuario.findById(id);
      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Verificar que sea dueño
      if (usuario.tipoUsuario !== 'dueño') {
        return res.status(400).json({ error: 'Solo los dueños pueden tener unidades' });
      }

      // Verificar que no exista el número económico
      const unidadExistente = usuario.unidades.find(u => u.numeroEconomico === numeroEconomico);
      if (unidadExistente) {
        return res.status(400).json({ error: 'Ya existe una unidad con ese número económico' });
      }

      usuario.unidades.push({
        numeroEconomico,
        placa,
        modelo,
        capacidad,
        rutaAsignada,
        estado: 'activo'
      });

      await usuario.save();

      res.json({
        message: 'Unidad agregada exitosamente',
        unidades: usuario.unidades
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Obtener unidades de un dueño
  async obtenerUnidades(req, res) {
    try {
      const { id } = req.params;
      const usuario = await Usuario.findById(id);

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      res.json({
        unidades: usuario.unidades,
        total: usuario.unidades.length,
        activas: usuario.unidades.filter(u => u.estado === 'activo').length
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Listar usuarios (con filtros)
  async listarUsuarios(req, res) {
    try {
      const { tipoUsuario, activo, page = 1, limit = 10 } = req.query;

      const filtro = {};
      if (tipoUsuario) filtro.tipoUsuario = tipoUsuario;
      if (activo !== undefined) filtro.activo = activo === 'true';

      const usuarios = await Usuario.find(filtro)
        .select('nombre apellido email tipoUsuario unidades activo createdAt')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ createdAt: -1 });

      const total = await Usuario.countDocuments(filtro);

      res.json({
        usuarios,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new UsuariosController();