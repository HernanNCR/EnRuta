const express = require("express");
const router = express.Router();
const Colectivos = require("../models/colectivos");

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

// crear colectivo
router.post("/", async (requestAnimationFrame, res) => {
  try {
    const { numero_economico, lugaresDisponibles } = requestAnimationFrame.body;
    const newColectivo = await Colectivos.create({
      numero_economico,
      lugaresDisponibles,
    });
    res.status(201).json(newColectivo);
  } catch (err) {
    res.status(400).json({ errpr: err.message });
  }
});

// actualizar colectivo

router.put("/:id", async (requestAnimationFrame, res) => {
  try {
    const updateColectivo = await Colectivos.findByIdAndUpdate(
      requestAnimationFrame.params.id,
      requestAnimationFrame.body,
      { new: true }
    );
    if (!updateColectivo)
      return res.status(404).json({ error: "No econtrado0" });
    res.json(updateColectivo);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// eliminar colectivo}

router.delete("/:id", async (req, res) => {
  try {
    const deleted = await Colectivos.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: "no encontrado" });
    res.json({ message: "Colectivo eliminado" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// actualizar ubicacion

router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { latitud, longitud } = req.body;

  try {
    const actualizado = await Colectivos.findByIdAndUpdate(
      id,
      { latitud, longitud },
      { new: true } // devuelve el documento actualizado
    );
    res.json(actualizado);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// endpoint al sensor de python
// PUT /api/ColectivosRutas/:id/pasajeros
router.put('/:id/pasajeros', async (req, res) => {
  const { id } = req.params;
  const { delta } = req.body; // entero: +1 para liberar asiento, -1 para ocupar
  if (typeof delta !== 'number') {
    return res.status(400).json({ error: 'delta (number) requerido en body' });
  }

  try {
    // Opción simple: read-modify-write (suficiente para prototipo)
    const colectivo = await Colectivos.findById(id);
    if (!colectivo) return res.status(404).json({ error: 'Colectivo no encontrado' });

    let nuevos = (colectivo.lugaresDisponibles || 0) + delta;
    if (nuevos < 0) nuevos = 0;

    colectivo.lugaresDisponibles = nuevos;
    const actualizado = await colectivo.save();

    res.json(actualizado);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
