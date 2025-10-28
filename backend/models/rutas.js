const mongoose = require("mongoose");

const RutasSchema = new mongoose.Schema({
  colorRuta: { type: String, required: true },
  coordenadasA: {
    lat: { type: mongoose.Schema.Types.Decimal128, required: true },
    lng: { type: mongoose.Schema.Types.Decimal128, required: true },
  },
  coordenadasB: {
    lat: { type: mongoose.Schema.Types.Decimal128, required: true },
    lng: { type: mongoose.Schema.Types.Decimal128, required: true },
  },
  rute: { type: Number, required: true },
});


module.exports = mongoose.model("Rutas", RutasSchema);