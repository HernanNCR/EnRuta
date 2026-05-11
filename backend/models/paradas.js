const mongoose = require("mongoose");

const ParadaSchema = new mongoose.Schema({
  nombre: { type: String, default: "" },
  ubicacion: {
    lat: { type: mongoose.Schema.Types.Decimal128, required: true },
    lng: { type: mongoose.Schema.Types.Decimal128, required: true },
  },
  rutas: [{ type: Number }],
}, {
  timestamps: true,
});

module.exports = mongoose.model("Paradas", ParadaSchema);
