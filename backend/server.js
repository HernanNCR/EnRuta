const express = require("express");
const dotenv = require("dotenv");

// Importar módulos compartidos
const { connectDB } = require("./shared/db");
const { connectRedis } = require("./shared/cache");
const logger = require("./shared/logger");
const { cors, helmet, limiter, requestLogger, errorHandler } = require("./shared/middleware");

// Importar servicios
const colectivosRoutes = require("./services/colectivos/routes");
const rutasRoutes = require("./services/rutas/routes");
const colectivosRutasRoutes = require("./routes/colectivos_rutas");
const sensoresRoutes = require("./services/sensores/routes");
const notificacionesRoutes = require("./services/notificaciones/routes");
const pagosRoutes = require("./services/pagos/routes");
const usuariosRoutes = require("./services/usuarios/routes");
const healthRoutes = require("./services/health/routes");

// Inicializar colas
const { notificationQueue } = require("./queue/notifications");

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware global
app.use(helmet);
app.use(cors);
app.use(limiter);
app.use(requestLogger);
app.use(express.json());

// Rutas de API
app.get("/api/hello", (req, res) => {
  res.json({ message: "Servidor funcionando" });
});

app.use('/api/colectivos', colectivosRoutes);
app.use('/api/rutas', rutasRoutes);
app.use('/api/ColectivosRutas', colectivosRutasRoutes);
app.use('/api/sensores', sensoresRoutes);
app.use('/api/notificaciones', notificacionesRoutes);
app.use('/api/pagos', pagosRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/health', healthRoutes);

// Middleware de error
app.use(errorHandler);

async function startServer() {
  try {
    await connectDB();
    await connectRedis();

    app.listen(PORT, () => {
      logger.info(`Servidor corriendo en puerto ${PORT}`);
    });
  } catch (err) {
    logger.error("Error al iniciar servidor:", err.message);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  await notificationQueue.close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('SIGINT received, shutting down gracefully');
  await notificationQueue.close();
  process.exit(0);
});

startServer();
