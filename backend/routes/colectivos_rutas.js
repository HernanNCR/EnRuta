const express = require("express");
const router = express.Router();
const Colectivos = require("../models/colectivos");
const Rutas = require("../models/rutas");

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

// Crear coordenada
router.post('/guardar-ruta', async (req, res) => {
  try {
    const { geojson } = req.body;

    const coordenadas = geojson.features[0].geometry.coordinates;
    console.log("📍 Coordenadas obtenidas:", coordenadas);

    const [coordenadasA, coordenadasB] = coordenadas;

    const colorRuta = "red";
    const rute = 91;

    const newRuta = await Rutas.create({
      colorRuta,
      coordenadasA: {
        lng: coordenadasA[0],
        lat: coordenadasA[1],
      },
      coordenadasB: {
        lng: coordenadasB[0],
        lat: coordenadasB[1],
      },
      rute,
    });

    console.log("✅ Nueva ruta guardada:", newRuta);

    res.status(200).json({
      message: "Ruta guardada correctamente",
      newRuta,
    });

  } catch (error) {
    console.error("❌ Error al guardar ruta:", error);
    res.status(500).json({ error: "Error al guardar ruta" });
  }
});

// GET /rutas
router.get("/rutas_coordenadas", async (req, res) => {
  try {
    const rutas = await Rutas.find();

    const rutasConGeojson = rutas.map(r => ({
      _id: r._id,
      colorRuta: r.colorRuta,
      rute: r.rute,
      coordenadasA: r.coordenadasA,
      coordenadasB: r.coordenadasB,
      geojson: JSON.stringify({
        type: "LineString",
        coordinates: [
          [parseFloat(r.coordenadasA.lng.toString()), parseFloat(r.coordenadasA.lat.toString())],
          [parseFloat(r.coordenadasB.lng.toString()), parseFloat(r.coordenadasB.lat.toString())],
        ],
      }),
    }));

    res.json(rutasConGeojson);
  } catch (err) {
    res.status(500).json({ message: err.message });
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





module.exports = router;
