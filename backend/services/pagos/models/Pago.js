const mongoose = require("mongoose");

const PagoSchema = new mongoose.Schema({
  usuarioId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true
  },
  colectivoId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Colectivos',
    required: true
  },
  monto: {
    type: mongoose.Schema.Types.Decimal128,
    required: true,
    min: 0
  },
  metodoPago: {
    type: String,
    enum: ['efectivo', 'tarjeta', 'transferencia', 'wallet'],
    required: true
  },
  estado: {
    type: String,
    enum: ['pendiente', 'completado', 'fallido', 'reembolsado'],
    default: 'pendiente'
  },
  referenciaExterna: {
    type: String,
    sparse: true // Permite null pero único si existe
  },
  descripcion: {
    type: String,
    default: 'Pago por viaje en colectivo'
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed // Para datos adicionales del proveedor de pagos
  }
}, {
  timestamps: true
});

// Índices para optimización
PagoSchema.index({ usuarioId: 1, createdAt: -1 });
PagoSchema.index({ estado: 1 });
PagoSchema.index({ referenciaExterna: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model("Pago", PagoSchema);