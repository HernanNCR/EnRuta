const express = require("express");
const router = express.Router();
const usuariosController = require("./controllers/usuariosController");

// Crear usuario
router.post("/", usuariosController.crearUsuario.bind(usuariosController));

// Listar usuarios
router.get("/", usuariosController.listarUsuarios.bind(usuariosController));

// Obtener usuario específico
router.get("/:id", usuariosController.obtenerUsuario.bind(usuariosController));

// Actualizar usuario
router.put("/:id", usuariosController.actualizarUsuario.bind(usuariosController));

// Agregar unidad a dueño
router.post("/:id/unidades", usuariosController.agregarUnidad.bind(usuariosController));

// Obtener unidades de un dueño
router.get("/:id/unidades", usuariosController.obtenerUnidades.bind(usuariosController));

module.exports = router;