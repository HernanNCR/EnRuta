const express = require("express"); // Framework web para crear routers. Conectado a la definición de rutas API.
const router = express.Router(); // Instancia del router de Express. Conectado a agrupar rutas relacionadas con health checks.
const healthService = require("./service"); // Servicio de health. Conectado a la lógica de chequeos de base de datos y sistema.

// Endpoint de health check
router.get("/", async (req, res) => { // Ruta GET para health check básico. Conectada al servicio que verifica estado general.
  try {
    const health = await healthService.getHealthStatus(); // Obtiene estado de health. Conectado a chequeos de DB y Redis.
    const statusCode = health.status === 'healthy' ? 200 : 503; // Código de estado basado en health. Conectado a respuestas HTTP.
    res.status(statusCode).json(health); // Respuesta JSON con estado. Conectada a monitoreo externo.
  } catch (error) { // Manejo de errores.
    res.status(503).json({ // Respuesta de error de servicio.
      status: 'error', // Estado de error.
      error: error.message, // Mensaje de error. Conectado al logging.
      timestamp: new Date().toISOString() // Timestamp. Conectado a trazabilidad.
    });
  }
});

// Health check detallado
router.get("/detailed", async (req, res) => { // Ruta GET para health check detallado. Conectada al servicio para información completa.
  try {
    const health = await healthService.getHealthStatus(); // Obtiene estado detallado.
    res.json(health); // Respuesta JSON detallada. Conectada a diagnósticos.
  } catch (error) { // Manejo de errores.
    res.status(500).json({ // Respuesta de error interno.
      status: 'error',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; // Exporta el router. Conectado al montaje en server.js bajo /api/health.