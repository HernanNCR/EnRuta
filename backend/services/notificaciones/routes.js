const express = require("express");
const router = express.Router();
const notificacionesService = require("./service");

// Enviar notificación manual
router.post("/enviar", async (req, res) => {
  try {
    const { tipo, datos } = req.body;
    await notificacionesService.enviarNotificacion(tipo, datos);
    res.json({ message: "Notificación enviada" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;