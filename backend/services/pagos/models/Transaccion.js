const mongoose = require("mongoose");

const TransaccionSchema = new mongoose.Schema({
  pagoId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Pago',
    required: true
  },
  tipo: {
    type: String,
    enum: ['cobro', 'reembolso', 'cargo_extra'],
    required: true
  },
  monto: {
    type: mongoose.Schema.Types.Decimal128,
    required: true
  },
  descripcion: String,
  procesadoPor: {
    type: String,
    enum: ['stripe', 'paypal', 'mercadopago', 'efectivo', 'transferencia'],
    required: true
  },
  estado: {
    type: String,
    enum: ['procesando', 'exitoso', 'fallido'],
    default: 'procesando'
  },
  metadata: mongoose.Schema.Types.Mixed
}, {
  timestamps: true
});

TransaccionSchema.index({ pagoId: 1 });
TransaccionSchema.index({ procesadoPor: 1, createdAt: -1 });

module.exports = mongoose.model("Transaccion", TransaccionSchema);