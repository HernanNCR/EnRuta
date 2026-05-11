const mongoose = require("mongoose"); // Librería para modelar datos en MongoDB. Conectada a la base de datos para definir esquemas y modelos.

const ColectivoSchema = new mongoose.Schema({ // Esquema de Mongoose para el modelo de Colectivo. Define la estructura de datos para colectivos en la base de datos.
  numero_economico: { type: Number, required: true }, // Número económico del colectivo. Campo requerido, usado para identificar el colectivo. Conectado a la UI y servicios de colectivos.
  placa: { type: String }, // Placa del vehículo. Campo opcional, usado para registro adicional. Conectado a datos administrativos.
  latitud: { type: mongoose.Schema.Types.Decimal128, required: true }, // Latitud de la ubicación del colectivo. Campo requerido, usado para posicionamiento en mapas. Conectado al GPS y frontend.
  longitud: { type: mongoose.Schema.Types.Decimal128, required: true }, // Longitud de la ubicación del colectivo. Campo requerido, usado para posicionamiento. Conectado al GPS y frontend.
  lugaresDisponibles: { type: Number, required: true }, // Número de lugares disponibles en el colectivo. Campo requerido, usado para mostrar disponibilidad. Conectado a la UI de usuarios.
  rute: { type: Number, required: true }, // Número de ruta asignada al colectivo. Campo requerido, usado para asociar con rutas. Conectado al modelo de rutas y servicios.
});

module.exports = mongoose.model("Colectivos", ColectivoSchema); // Exporta el modelo Colectivos. Conectado a controladores y rutas que usan este modelo para operaciones CRUD.
