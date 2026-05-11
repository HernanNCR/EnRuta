const express = require("express");
const router = express.Router();
const sensorManager = require("./manager");

// Obtener lista de sensores disponibles
router.get("/", (req, res) => {
  res.json({
    sensors: sensorManager.listSensors(),
    active: Array.from(sensorManager.activeProcesses.keys())
  });
});

// Iniciar un sensor
router.post("/:type/start", async (req, res) => {
  try {
    const { type } = req.params;
    await sensorManager.startSensor(type);
    res.json({ message: `Sensor ${type} started` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Detener un sensor
router.post("/:type/stop", (req, res) => {
  const { type } = req.params;
  sensorManager.stopSensor(type);
  res.json({ message: `Sensor ${type} stopped` });
});

// Obtener datos de un sensor
router.get("/:type/data", async (req, res) => {
  try {
    const { type } = req.params;
    const data = await sensorManager.getSensorData(type);
    res.json({ data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;