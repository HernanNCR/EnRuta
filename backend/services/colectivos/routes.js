const express = require("express");
const router = express.Router();
const Colectivos = require("../../models/colectivos");
const Rutas = require("../../models/rutas");

// Obtener todos los rutes
async function listarRutas() {
  try {
    const rutas = await Colectivos.find({}, { rute: 1, _id: 0 }); // solo rute
    console.log(rutas);
  } catch (err) {
    console.error(err);
  }
}

listarRutas();

// Obtener todas las rutas únicas
router.get("/rutas", async (req, res) => {
  try {
    const rutas = await Colectivos.distinct("rute"); // 🔥 devuelve valores únicos
    res.json(rutas);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ver todos los colectivos
router.get("/", async (req, res) => {
  try {
    const colectivos_rutas = await Colectivos.find().sort({ createdAt: -1 });
    res.json(colectivos_rutas);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Obtener colectivos por ruta
router.get("/ruta/:rute", async (req, res) => {
  const rutaSeleccionada = req.params.rute; // toma la ruta que envía el frontend
  try {
    const colectivos = await Colectivos.find({ rute: rutaSeleccionada });
    console.log("Ruta recibida:", rutaSeleccionada);
    console.log("Colectivos encontrados:", colectivos);
    res.json(colectivos);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;