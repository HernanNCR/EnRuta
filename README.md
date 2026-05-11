# EnRuta - Sistema de Transporte Público

Sistema modular y escalable para gestión de transporte público con arquitectura de microservicios.

## Arquitectura

- **Backend**: Node.js con Express y arquitectura modular
- **Base de datos**: MongoDB con Mongoose
- **Cache**: Redis para sesiones y caché distribuido
- **Colas**: Bull Queue para procesamiento asíncrono
- **API Gateway**: NGINX con load balancing y seguridad
- **Contenerización**: Docker + Docker Compose
- **Testing**: Jest con Supertest y mocks

## Servicios

### 1. Colectivos
- Gestión de colectivos y rutas
- Endpoints: `/api/colectivos`

### 2. Sensores
- Módulo extensible para sensores (GPS, simulador, etc.)
- Endpoints: `/api/sensores`

### 3. Usuarios
- Gestión de usuarios y dueños con múltiples unidades
- Endpoints: `/api/usuarios`

### 4. Pagos
- Sistema de pagos extensible (preparado para tu compañero)
- Endpoints: `/api/pagos`

### 5. Health
- Monitoreo de salud del sistema
- Endpoints: `/api/health`

## Instalación y Configuración

### Prerrequisitos

- Node.js 18+
- MongoDB
- Redis
- Docker (opcional para contenerización)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd EnRuta
   ```

2. **Instalar dependencias del backend**
   ```bash
   cd backend
   npm install
   ```

3. **Configurar variables de entorno**
   Crear archivo `.env` en `backend/`:
   ```env
   NODE_ENV=development
   PORT=3000
   MONGO_URI=mongodb://localhost:27017/enruta
   REDIS_URL=redis://localhost:6379
   JWT_SECRET=your-secret-key
   ```

4. **Instalar y configurar MongoDB**
   ```bash
   # Usando Docker
   docker run -d -p 27017:27017 --name mongodb mongo:latest

   # O instalar localmente desde https://www.mongodb.com/
   ```

5. **Instalar y configurar Redis**
   ```bash
   # Usando Docker
   docker run -d -p 6379:6379 --name redis redis:latest

   # O instalar localmente desde https://redis.io/
   ```

## Ejecución

### Desarrollo

```bash
cd backend
npm start
```

El servidor iniciará en `http://localhost:3000`

### Tests

```bash
cd backend
npm test
```

### Producción con Docker

```bash
# Construir y ejecutar todos los servicios
docker compose up --build -d

# Ver logs
docker compose logs -f

# Detener servicios
docker compose down
```

## API Endpoints

### Colectivos
- `GET /api/colectivos/rutas` - Lista todas las rutas
- `GET /api/colectivos` - Lista todos los colectivos
- `GET /api/colectivos/ruta/:rute` - Colectivos por ruta

### Sensores
- `GET /api/sensores` - Lista sensores disponibles y activos
- `POST /api/sensores/:type/start` - Iniciar sensor
- `POST /api/sensores/:type/stop` - Detener sensor

### Usuarios
- `POST /api/usuarios` - Crear usuario
- `GET /api/usuarios` - Listar usuarios (con paginación)
- `GET /api/usuarios/:id` - Obtener usuario específico
- `PUT /api/usuarios/:id` - Actualizar usuario
- `POST /api/usuarios/:id/unidades` - Agregar unidad a dueño
- `GET /api/usuarios/:id/unidades` - Obtener unidades de dueño

### Pagos
- `POST /api/pagos` - Crear pago
- `GET /api/pagos/usuario/:usuarioId` - Pagos de usuario
- `POST /api/pagos/procesar` - Procesar pago (extensible)
- `POST /api/pagos/:pagoId/reembolsar` - Reembolsar pago

### Health
- `GET /api/health` - Estado básico de salud
- `GET /api/health/detailed` - Estado detallado con métricas

## Arquitectura Modular

### Estructura de Servicios

```
backend/
├── services/
│   ├── colectivos/
│   │   ├── routes.js
│   │   └── controllers/
│   ├── sensores/
│   │   ├── routes.js
│   │   ├── manager.js
│   │   └── controllers/
│   ├── usuarios/
│   │   ├── routes.js
│   │   ├── models/
│   │   └── controllers/
│   ├── pagos/
│   │   ├── routes.js
│   │   ├── models/
│   │   └── controllers/
│   └── health/
│       ├── routes.js
│       └── service.js
├── shared/
│   ├── db.js
│   ├── cache.js
│   ├── logger.js
│   └── queue.js
├── models/
├── tests/
└── server.js
```

### Agregar Nuevo Servicio

1. Crear carpeta en `services/nuevo-servicio/`
2. Crear `routes.js`, `controllers/`, `models/` según necesidad
3. Importar rutas en `server.js`
4. Agregar tests en `tests/`

## Testing

Los tests usan mocks completos para evitar dependencias externas:

- **DB**: Mock de MongoDB/Mongoose
- **Redis**: Mock de cliente Redis
- **Logger**: Mock de funciones de logging
- **Controladores**: Mocks de métodos de negocio

```bash
cd backend
npm test
```

## Despliegue

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - MONGO_URI=mongodb://mongodb:27017/enruta
      - REDIS_URL=redis://redis:6379
    depends_on:
      - mongodb
      - redis

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"

  redis:
    image: redis:latest
    ports:
      - "6379:6379"

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
```

### Variables de Entorno Producción

```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb://mongodb:27017/enruta
REDIS_URL=redis://redis:6379
JWT_SECRET=your-production-secret
LOG_LEVEL=info
```

## Monitoreo

- Health checks en `/api/health`
- Logs estructurados con Winston
- Métricas de sistema incluidas

## Extensibilidad

- **Sensores**: Arquitectura preparada para nuevos tipos de sensores
- **Pagos**: Proveedores extensibles (Stripe, PayPal, etc.)
- **Usuarios**: Soporte para múltiples unidades por dueño
- **Microservicios**: Fácil separación en servicios independientes

## Contribución

1. Crear rama para nueva funcionalidad
2. Escribir tests para cambios
3. Ejecutar `npm test` antes de push
4. Seguir estructura modular existente

## Licencia

MIT