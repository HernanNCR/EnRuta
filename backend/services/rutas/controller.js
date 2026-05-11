const Rutas = require("../../models/rutas");

class RutasController {
  async getAll(req, res) {
    try {
      const rutas = await Rutas.find();
      res.json(rutas);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
}

module.exports = new RutasController();