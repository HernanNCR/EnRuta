FROM nginx:alpine

# Copiar configuración de nginx
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Crear directorios para logs
RUN mkdir -p /var/log/nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

EXPOSE 80