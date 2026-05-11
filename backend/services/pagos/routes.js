const express = require("express"); // Framework web para crear routers. Conectado a la definición de rutas API.
const router = express.Router(); // Instancia del router de Express. Conectado a agrupar rutas relacionadas con pagos.
const pagosController = require("./controllers/pagosController"); // Controlador de pagos. Conectado a la lógica de negocio para operaciones de pagos.

// Crear un nuevo pago
router.post("/", pagosController.crearPago.bind(pagosController)); // Ruta POST para crear pago. Conectada al controlador que maneja la creación.

// Obtener pagos de un usuario
router.get("/usuario/:usuarioId", pagosController.obtenerPagosUsuario.bind(pagosController)); // Ruta GET para obtener pagos por usuario. Conectada al controlador que filtra pagos.

// Procesar pago con proveedor específico
router.post("/procesar", pagosController.procesarPago.bind(pagosController)); // Ruta POST para procesar pago. Conectada al controlador que integra con proveedores.

// Reembolsar pago
router.post("/:pagoId/reembolsar", pagosController.reembolsarPago.bind(pagosController)); // Ruta POST para reembolsar. Conectada al controlador de reembolsos.

// Obtener detalles de un pago
router.get("/:pagoId", async (req, res) => { // Ruta GET para detalles de pago. Conectada a consultas directas (placeholder).
  try {
    const { pagoId } = req.params; // ID del pago desde parámetros de URL. Conectado a la identificación del pago.
    // Placeholder - implementar consulta real
    res.json({ // Respuesta JSON con detalles del pago. Conectada al frontend para mostrar información.
      id: pagoId, // ID del pago. Conectado a la base de datos.
      estado: 'completado', // Estado del pago. Conectado a estados de transacción.
      monto: 25.50 // Monto del pago. Conectado a cálculos financieros.
    });
  } catch (error) { // Manejo de errores. Conectado al logging y respuestas de error.
    res.status(500).json({ error: error.message }); // Respuesta de error. Conectada al cliente.
  }
});

module.exports = router; // Exporta el router. Conectado al montaje en server.js bajo /api/pagos.