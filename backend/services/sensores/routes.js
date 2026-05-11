const express = require("express"); // Framework web para crear routers. Conectado a la definición de rutas API.
const router = express.Router(); // Instancia del router de Express. Conectado a agrupar rutas relacionadas con sensores.
const sensorManager = require("./manager"); // Gestor de sensores. Conectado a la lógica de control de sensores (iniciar, detener, obtener datos).

// Obtener lista de sensores disponibles
router.get("/", (req, res) => { // Ruta GET para listar sensores. Conectada al manager que devuelve sensores disponibles y activos.
  res.json({ // Respuesta JSON con lista de sensores. Conectada al frontend para mostrar opciones.
    sensors: sensorManager.listSensors(), // Lista de sensores. Conectada al manager.
    active: Array.from(sensorManager.activeProcesses.keys()) // Sensores activos. Conectada a procesos en ejecución.
  });
});

// Iniciar un sensor
router.post("/:type/start", async (req, res) => { // Ruta POST para iniciar sensor. Conectada al manager que maneja el inicio.
  try {
    const { type } = req.params; // Tipo de sensor desde URL. Conectado a la identificación del sensor.
    await sensorManager.startSensor(type); // Llama al manager para iniciar. Conectado a procesos asíncronos.
    res.json({ message: `Sensor ${type} started` }); // Respuesta de éxito. Conectada al cliente.
  } catch (err) { // Manejo de errores.
    res.status(500).json({ error: err.message }); // Respuesta de error. Conectada al logging.
  }
});

// Detener un sensor
router.post("/:type/stop", (req, res) => { // Ruta POST para detener sensor. Conectada al manager que maneja la detención.
  const { type } = req.params; // Tipo de sensor. Conectado a la identificación.
  sensorManager.stopSensor(type); // Llama al manager para detener. Conectado a procesos activos.
  res.json({ message: `Sensor ${type} stopped` }); // Respuesta de éxito.
});

// Obtener datos de un sensor
router.get("/:type/data", async (req, res) => { // Ruta GET para obtener datos de sensor. Conectada al manager que recupera datos.
  try {
    const { type } = req.params; // Tipo de sensor.
    const data = await sensorManager.getSensorData(type); // Obtiene datos. Conectado a lecturas del sensor.
    res.json({ data }); // Respuesta con datos. Conectada al frontend para visualización.
  } catch (err) { // Manejo de errores.
    res.status(500).json({ error: err.message }); // Respuesta de error.
  }
});

module.exports = router; // Exporta el router. Conectado al montaje en server.js bajo /api/sensores.