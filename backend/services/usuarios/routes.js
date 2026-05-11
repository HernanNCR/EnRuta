const express = require("express"); // Framework web para crear routers. Conectado a la definición de rutas API.
const router = express.Router(); // Instancia del router de Express. Conectado a agrupar rutas relacionadas con usuarios.
const usuariosController = require("./controllers/usuariosController"); // Controlador de usuarios. Conectado a la lógica de negocio para operaciones CRUD de usuarios.

// Crear usuario
router.post("/", usuariosController.crearUsuario.bind(usuariosController)); // Ruta POST para crear usuario. Conectada al controlador que maneja la creación.

// Listar usuarios
router.get("/", usuariosController.listarUsuarios.bind(usuariosController)); // Ruta GET para listar usuarios. Conectada al controlador que recupera la lista.

// Obtener usuario específico
router.get("/:id", usuariosController.obtenerUsuario.bind(usuariosController)); // Ruta GET para obtener usuario por ID. Conectada al controlador que filtra por ID.

// Actualizar usuario
router.put("/:id", usuariosController.actualizarUsuario.bind(usuariosController)); // Ruta PUT para actualizar usuario. Conectada al controlador de actualizaciones.

// Agregar unidad a dueño
router.post("/:id/unidades", usuariosController.agregarUnidad.bind(usuariosController)); // Ruta POST para agregar unidad a dueño. Conectada al controlador que gestiona unidades.

// Obtener unidades de un dueño
router.get("/:id/unidades", usuariosController.obtenerUnidades.bind(usuariosController)); // Ruta GET para obtener unidades de dueño. Conectada al controlador que lista unidades.

module.exports = router; // Exporta el router. Conectado al montaje en server.js bajo /api/usuarios.