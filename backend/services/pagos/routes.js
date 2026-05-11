const express = require("express");
const router = express.Router();
const pagosController = require("./controllers/pagosController");

// Crear un nuevo pago
router.post("/", pagosController.crearPago.bind(pagosController));

// Obtener pagos de un usuario
router.get("/usuario/:usuarioId", pagosController.obtenerPagosUsuario.bind(pagosController));

// Procesar pago con proveedor específico
router.post("/procesar", pagosController.procesarPago.bind(pagosController));

// Reembolsar pago
router.post("/:pagoId/reembolsar", pagosController.reembolsarPago.bind(pagosController));

// Obtener detalles de un pago
router.get("/:pagoId", async (req, res) => {
  try {
    const { pagoId } = req.params;
    // Placeholder - implementar consulta real
    res.json({
      id: pagoId,
      estado: 'completado',
      monto: 25.50
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;