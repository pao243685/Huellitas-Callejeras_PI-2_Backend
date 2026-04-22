# Animals Service

Backend del servicio de gestión de animales para el proyecto Huellitas Callejeras.

## Descripción

Servicio construido con NestJS y Prisma que expone la API de gestión de refugios, animales, movimientos, roles y usuarios.

## Requisitos

- Docker
- Docker Compose

## Instalación y ejecución con Docker

1. Clona el repositorio desde GitHub y navega al directorio raíz del proyecto:

   ```bash
   git clone https://github.com/pao243685/Huellitas-Callejeras_PI-2_Backend.git 
   cd animals-service
   ```


2. Crea un archivo `.env` en la raíz del proyecto con las variables necesarias:

```env
POSTGRES_USER
POSTGRES_PASSWORD
POSTGRES_DB

NODE_ENV
DATABASE_URL
PORT

JWT_SECRET
```

3. Construye y levanta los servicios con Docker Compose:

```bash
docker compose up --build
```

Esto levantará:
- La aplicación NestJS en el puerto 3001
- La base de datos local en PostgreSQL
- Ejecutará automáticamente las migraciones de Prisma

4. La aplicación estará disponible en:
- API: `http://localhost:3001/api/v1`
- Swagger: `http://localhost:3001/api/v1/docs`

## Variables de entorno

Las variables necesarias se configuran en el archivo `.env`:

- `DATABASE_URL`: URL de conexión a PostgreSQL (configurada para usar el contenedor `db`)
- `JWT_SECRET`: Secreto para firmar tokens JWT
- `PORT`: Puerto del servidor (3001 por defecto)
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`: Credenciales de la base de datos

## Comandos útiles con Docker

- Levantar servicios en segundo plano:

```bash
docker compose up -d
```

- Detener servicios:

```bash
docker compose down
```

- Ver logs:

```bash
docker compose logs -f
```


## Estructura general

- `src/` - código fuente de NestJS
- `prisma/` - esquema de Prisma y migraciones
- `uploads/` - archivos estáticos subidos
- `swagger.json` - definición de la API
- `Dockerfile` - configuración del contenedor de la aplicación
- `docker-compose.yml` - configuración de servicios


src/
├── animals/          # Gestión de animales (CRUD + stored procedure de registro)
├── movements/        # Movimientos de entrada/salida con validación secuencial
├── statistics/       # Indicadores, historial y alertas via vistas y funciones SQL
├── etiquetas/        # Sistema de etiquetas asignables a animales
├── refugio/          # Gestión de refugios y roles
├── users/            # Administración de usuarios por refugio
├── auth/             # Autenticación JWT, guards, estrategias y 2FA
└── shared/           # PrismaService global compartido entre módulos

## Notas

- El backend sirve archivos estáticos desde `uploads/` en la ruta `/uploads`.
- El prefijo global de la API es `api/v1`.
- Asegúrate de que `JWT_SECRET` esté configurado antes de iniciar el servidor.
- Los archivos subidos se persisten en el volumen `uploads`.
