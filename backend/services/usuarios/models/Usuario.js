const mongoose = require("mongoose");

const UsuarioSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: true,
    trim: true
  },
  apellido: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  telefono: {
    type: String,
    trim: true
  },
  tipoUsuario: {
    type: String,
    enum: ['pasajero', 'dueño', 'conductor', 'admin'],
    default: 'pasajero'
  },
  // Para dueños con múltiples unidades
  unidades: [{
    numeroEconomico: {
      type: Number,
      required: true
    },
    placa: String,
    modelo: String,
    capacidad: Number,
    rutaAsignada: Number,
    estado: {
      type: String,
      enum: ['activo', 'mantenimiento', 'inactivo'],
      default: 'activo'
    }
  }],
  // Información adicional
  fechaNacimiento: Date,
  documentoIdentidad: {
    tipo: {
      type: String,
      enum: ['cedula', 'pasaporte', 'licencia']
    },
    numero: String
  },
  direccion: {
    calle: String,
    ciudad: String,
    estado: String,
    codigoPostal: String,
    coordenadas: {
      lat: Number,
      lng: Number
    }
  },
  // Preferencias y configuración
  preferencias: {
    notificaciones: {
      email: { type: Boolean, default: true },
      sms: { type: Boolean, default: true },
      push: { type: Boolean, default: true }
    },
    idioma: { type: String, default: 'es' },
    moneda: { type: String, default: 'MXN' }
  },
  // Estado de la cuenta
  activo: {
    type: Boolean,
    default: true
  },
  ultimoAcceso: Date,
  metadata: mongoose.Schema.Types.Mixed
}, {
  timestamps: true
});

// Índices para optimización
UsuarioSchema.index({ email: 1 }, { unique: true });
UsuarioSchema.index({ tipoUsuario: 1 });
UsuarioSchema.index({ 'unidades.numeroEconomico': 1 });
UsuarioSchema.index({ activo: 1 });

// Virtual para nombre completo
UsuarioSchema.virtual('nombreCompleto').get(function() {
  return `${this.nombre} ${this.apellido}`;
});

// Método para verificar si es dueño
UsuarioSchema.methods.esDueño = function() {
  return this.tipoUsuario === 'dueño' && this.unidades.length > 0;
};

// Método para obtener unidades activas
UsuarioSchema.methods.getUnidadesActivas = function() {
  return this.unidades.filter(unidad => unidad.estado === 'activo');
};

module.exports = mongoose.model("Usuario", UsuarioSchema);