const Colectivos = require("../../models/colectivos");

class ColectivosController {
  async getAll(req, res) {
    try {
      const colectivos = await Colectivos.find().sort({ createdAt: -1 });
      res.json(colectivos);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }

  async getByRuta(req, res) {
    const rutaSeleccionada = req.params.rute;
    try {
      const colectivos = await Colectivos.find({ rute: rutaSeleccionada });
      res.json(colectivos);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }

  async getRutasUnicas(req, res) {
    try {
      const rutas = await Colectivos.distinct("rute");
      res.json(rutas);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
}

module.exports = new ColectivosController();