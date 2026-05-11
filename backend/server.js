const express = require("express"); // Framework web para Node.js, usado para crear el servidor HTTP y manejar rutas API. Conectado a todas las rutas de la aplicación.
const dotenv = require("dotenv"); // Librería para cargar variables de entorno desde archivo .env. Conectada a la configuración del puerto y conexiones de base de datos.

// Importar módulos compartidos
const { connectDB } = require("./shared/db"); // Función para conectar a MongoDB. Conectada al servicio de base de datos compartido usado por todos los modelos.
const { connectRedis } = require("./shared/cache"); // Función para conectar a Redis. Conectada al sistema de caché compartido para sesiones y datos temporales.
const logger = require("./shared/logger"); // Módulo de logging compartido. Conectado a todos los servicios para registrar eventos y errores.
const { cors, helmet, limiter, requestLogger, errorHandler } = require("./shared/middleware"); // Middlewares de seguridad y logging. Conectados al pipeline de Express para proteger y monitorear peticiones.

// Importar servicios
const colectivosRoutes = require("./services/colectivos/routes"); // Rutas del servicio de colectivos. Conectadas a endpoints para gestionar colectivos.
const rutasRoutes = require("./services/rutas/routes"); // Rutas del servicio de rutas. Conectadas a endpoints para obtener y gestionar rutas.
const colectivosRutasRoutes = require("./routes/colectivos_rutas"); // Rutas principales para colectivos y rutas usadas por el frontend. Conectadas a la API principal del mapa.
const sensoresRoutes = require("./services/sensores/routes"); // Rutas del servicio de sensores. Conectadas a endpoints para controlar sensores.
const notificacionesRoutes = require("./services/notificaciones/routes"); // Rutas del servicio de notificaciones. Conectadas a endpoints para enviar notificaciones.
const pagosRoutes = require("./services/pagos/routes"); // Rutas del servicio de pagos. Conectadas a endpoints para procesar pagos.
const usuariosRoutes = require("./services/usuarios/routes"); // Rutas del servicio de usuarios. Conectadas a endpoints CRUD de usuarios.
const healthRoutes = require("./services/health/routes"); // Rutas del servicio de healthcheck. Conectadas a endpoints para monitoreo del sistema.

// Inicializar colas
const { notificationQueue } = require("./queue/notifications"); // Cola de notificaciones usando Bull. Conectada al servicio de notificaciones para procesar envíos asíncronos.

dotenv.config();

const app = express(); // Instancia de la aplicación Express. Conectada a todas las configuraciones y rutas del servidor.
const PORT = process.env.PORT || 3000; // Puerto del servidor, obtenido de variables de entorno o valor por defecto. Conectado al listener del servidor.

// Middleware global
app.use(helmet); // Middleware de seguridad que establece headers HTTP seguros. Conectado a la protección contra ataques comunes.
app.use(cors); // Middleware para habilitar CORS (Cross-Origin Resource Sharing). Conectado a permitir peticiones desde el frontend Flutter.
app.use(limiter); // Middleware para limitar el número de peticiones por IP. Conectado a prevenir abuso y ataques DDoS.
app.use(requestLogger); // Middleware para loggear todas las peticiones entrantes. Conectado al sistema de logging compartido.
app.use(express.json()); // Middleware para parsear JSON en el body de las peticiones. Conectado a todos los endpoints que reciben datos JSON.

// Rutas de API
app.get("/api/hello", (req, res) => { // Endpoint de prueba para verificar que el servidor funciona. Conectado a healthchecks básicos.
  res.json({ message: "Servidor funcionando" });
});

app.use('/api/colectivos', colectivosRoutes); // Monta las rutas de colectivos bajo /api/colectivos. Conectadas al servicio de gestión de colectivos.
app.use('/api/rutas', rutasRoutes); // Monta las rutas de rutas bajo /api/rutas. Conectadas al servicio de gestión de rutas.
app.use('/api/ColectivosRutas', colectivosRutasRoutes); // Monta las rutas principales bajo /api/ColectivosRutas. Conectadas al frontend para mapas y datos.
app.use('/api/sensores', sensoresRoutes); // Monta las rutas de sensores bajo /api/sensores. Conectadas al servicio de control de sensores.
app.use('/api/notificaciones', notificacionesRoutes); // Monta las rutas de notificaciones bajo /api/notificaciones. Conectadas al servicio de envío de notificaciones.
app.use('/api/pagos', pagosRoutes); // Monta las rutas de pagos bajo /api/pagos. Conectadas al servicio de procesamiento de pagos.
app.use('/api/usuarios', usuariosRoutes); // Monta las rutas de usuarios bajo /api/usuarios. Conectadas al servicio de gestión de usuarios.
app.use('/api/health', healthRoutes); // Monta las rutas de healthcheck bajo /api/health. Conectadas al monitoreo del sistema.

// Middleware de error
app.use(errorHandler); // Middleware para manejar errores no capturados. Conectado al logging y respuesta de errores al cliente.

async function startServer() { // Función asíncrona para iniciar el servidor. Conectada a la inicialización de conexiones y listener.
  try {
    await connectDB(); // Conecta a MongoDB antes de iniciar el servidor. Conectada a la base de datos principal.
    await connectRedis(); // Conecta a Redis antes de iniciar el servidor. Conectada al caché.

    app.listen(PORT, () => { // Inicia el servidor en el puerto especificado. Conectado al listener de Express.
      logger.info(`Servidor corriendo en puerto ${PORT}`); // Loggea el inicio exitoso. Conectado al sistema de logging.
    });
  } catch (err) { // Manejo de errores durante el inicio.
    logger.error("Error al iniciar servidor:", err.message); // Loggea el error. Conectado al logging de errores.
    process.exit(1); // Termina el proceso con código de error. Conectado al manejo de fallos críticos.
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => { // Evento para shutdown graceful en sistemas Unix. Conectado al cierre ordenado del servidor.
  logger.info('SIGTERM received, shutting down gracefully'); // Loggea el evento. Conectado al logging.
  await notificationQueue.close(); // Cierra la cola de notificaciones. Conectada al servicio de colas.
  process.exit(0); // Termina el proceso exitosamente.
});

process.on('SIGINT', async () => { // Evento para shutdown graceful en Ctrl+C. Conectado al cierre ordenado.
  logger.info('SIGINT received, shutting down gracefully'); // Loggea el evento.
  await notificationQueue.close(); // Cierra la cola.
  process.exit(0); // Termina exitosamente.
});

startServer(); // Llama a la función para iniciar el servidor. Punto de entrada del script.
