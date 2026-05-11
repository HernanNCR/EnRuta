const express = require("express"); // Framework web para crear routers. Conectado a la definición de rutas API.
const router = express.Router(); // Instancia del router de Express. Conectado a agrupar rutas relacionadas con notificaciones.
const notificacionesService = require("./service"); // Servicio de notificaciones. Conectado a la lógica de envío y colas.

// Enviar notificación manual
router.post("/enviar", async (req, res) => { // Ruta POST para enviar notificación. Conectada al servicio que maneja el envío.
  try {
    const { tipo, datos } = req.body; // Tipo y datos desde el body. Conectados a la configuración de la notificación.
    await notificacionesService.enviarNotificacion(tipo, datos); // Llama al servicio. Conectado a la cola de notificaciones.
    res.json({ message: "Notificación enviada" }); // Respuesta de éxito. Conectada al cliente.
  } catch (err) { // Manejo de errores.
    res.status(500).json({ error: err.message }); // Respuesta de error. Conectada al logging.
  }
});

module.exports = router; // Exporta el router. Conectado al montaje en server.js bajo /api/notificaciones.