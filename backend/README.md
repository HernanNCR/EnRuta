# Backend EnRuta - Arquitectura Modular

## Estructura del Proyecto

```
backend/
├── services/           # Servicios modulares
│   ├── colectivos/     # Gestión de colectivos
│   ├── rutas/          # Gestión de rutas
│   ├── sensores/       # Gestión de sensores (extensible)
│   └── notificaciones/ # Sistema de notificaciones
├── shared/             # Código compartido
│   ├── db.js           # Conexión MongoDB
│   ├── cache.js        # Redis cache
│   ├── logger.js       # Winston logger
│   ├── middleware/     # Middlewares Express
│   └── utils/          # Utilidades
├── queue/              # Colas de trabajos (Bull)
├── models/             # Modelos Mongoose (legacy)
└── server.js           # Punto de entrada
```

## Escalabilidad

### Vertical (una máquina más poderosa)
- ✅ Caché Redis para reducir consultas DB
- ✅ Connection pooling MongoDB
- ✅ Logging centralizado
- ✅ Rate limiting
- ✅ Compresión gzip

### Horizontal (múltiples máquinas)
- ✅ Microservicios independientes
- ✅ Message queues (Bull + Redis)
- ✅ Sesiones distribuidas
- ✅ API Gateway ready (fácil agregar NGINX/Kong)

## Servicios

### Colectivos
- GET /api/colectivos - Listar todos
- GET /api/colectivos/ruta/:rute - Por ruta
- GET /api/colectivos/rutas - Rutas únicas

### Rutas
- GET /api/rutas - Listar rutas

### Sensores (Extensible)
- GET /api/sensores - Listar sensores
- POST /api/sensores/:type/start - Iniciar sensor
- POST /api/sensores/:type/stop - Detener sensor
- GET /api/sensores/:type/data - Obtener datos

### Notificaciones
- POST /api/notificaciones/enviar - Enviar notificación

## Próximos Pasos

1. **Docker**: Crear Dockerfile y docker-compose.yml
2. **Tests**: Agregar Jest tests
3. **API Gateway**: NGINX como load balancer
4. **Monitoring**: Health checks, métricas
5. **CI/CD**: GitHub Actions para deployment

## Ejecutar

```bash
npm install
npm run dev  # desarrollo
npm start    # producción
```

## Variables de Entorno

Copiar `.env.example` a `.env` y configurar:

- MONGO_URI: URL de MongoDB
- REDIS_URL: URL de Redis
- PORT: Puerto del servidor
- NODE_ENV: Entorno (development/production)