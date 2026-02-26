#!/bin/sh
set -e

echo "Esperando a PostgreSQL..."
until npx prisma migrate deploy 2>/dev/null; do
  echo "   DB no disponible, reintentando en 3s..."
  sleep 3
done

echo "Migraciones aplicadas"
echo "Iniciando servidor..."
exec node dist/main