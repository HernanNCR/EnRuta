const mongoose = require("mongoose");

const ColectivoSchema = new mongoose.Schema({
  numero_economico: { type: Number, required: true },
  placa: { type: String },
  latitud: { type: mongoose.Schema.Types.Decimal128, required: true },
  longitud: { type: mongoose.Schema.Types.Decimal128, required: true },
  lugaresDisponibles: { type: Number, required: true },
  rute: { type: Number, required: true },
});

module.exports = mongoose.model("Colectivos", ColectivoSchema);
