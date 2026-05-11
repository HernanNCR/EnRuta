#!/bin/sh

# Iniciar Redis en background
redis-server --daemonize yes

# Esperar a que Redis esté listo
echo "Esperando Redis..."
while ! redis-cli ping > /dev/null 2>&1; do
  sleep 1
done
echo "Redis está listo!"

# Iniciar la aplicación
echo "Iniciando aplicación..."
npm start