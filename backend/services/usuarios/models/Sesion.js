const mongoose = require("mongoose");

const SesionSchema = new mongoose.Schema({
  usuarioId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true
  },
  token: {
    type: String,
    required: true,
    unique: true
  },
  dispositivo: {
    tipo: String, // 'web', 'mobile', 'api'
    userAgent: String,
    ip: String
  },
  expiraEn: {
    type: Date,
    required: true
  },
  activo: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

SesionSchema.index({ usuarioId: 1 });
SesionSchema.index({ token: 1 }, { unique: true });
SesionSchema.index({ expiraEn: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model("Sesion", SesionSchema);