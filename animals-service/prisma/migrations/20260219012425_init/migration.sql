-- CreateEnum
CREATE TYPE "tamano_lista" AS ENUM ('pequeño', 'mediano', 'grande');

-- CreateEnum
CREATE TYPE "sexo_animal" AS ENUM ('Macho', 'Hembra');

-- CreateEnum
CREATE TYPE "movimiento_tipo" AS ENUM ('rescate', 'retorno', 'adopcion', 'defuncion');

-- CreateTable
CREATE TABLE "roles" (
    "id_roles" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nombre" VARCHAR(100) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id_roles")
);

-- CreateTable
CREATE TABLE "refugios" (
    "id_refugio" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nombre" VARCHAR(100) NOT NULL,
    "capacidad_max" INTEGER NOT NULL,
    "estado" VARCHAR(100) NOT NULL,
    "municipio" VARCHAR(100) NOT NULL,
    "colonia" TEXT NOT NULL,
    "calle" TEXT NOT NULL,
    "num_exterior" INTEGER,
    "num_interior" INTEGER,

    CONSTRAINT "refugios_pkey" PRIMARY KEY ("id_refugio")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id_usuario" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nombre" VARCHAR(100) NOT NULL,
    "apellido_p" VARCHAR(100) NOT NULL,
    "apellido_m" VARCHAR(100) NOT NULL,
    "contrasena" VARCHAR(100) NOT NULL,
    "email" TEXT NOT NULL,
    "activo" BOOLEAN NOT NULL,
    "rol_id" UUID NOT NULL,
    "refugio_id" UUID NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id_usuario")
);

-- CreateTable
CREATE TABLE "animales" (
    "id_animal" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nombre" VARCHAR(100) NOT NULL,
    "especie" VARCHAR(100) NOT NULL,
    "raza" VARCHAR(100) NOT NULL,
    "edad" INTEGER NOT NULL,
    "peso" DECIMAL(10,2) NOT NULL,
    "sexo" "sexo_animal" NOT NULL,
    "imagen" TEXT,
    "tamano" "tamano_lista" NOT NULL,
    "enfermedad_no_tratable" BOOLEAN NOT NULL,
    "discapacidad" BOOLEAN NOT NULL,
    "es_agresivo" BOOLEAN NOT NULL,
    "lugar" TEXT NOT NULL,
    "descripcion" TEXT NOT NULL,
    "usuario_id" UUID NOT NULL,
    "refugio_id" UUID NOT NULL,

    CONSTRAINT "animales_pkey" PRIMARY KEY ("id_animal")
);

-- CreateTable
CREATE TABLE "movimientos" (
    "id_movimiento" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tipo_movimiento" "movimiento_tipo" NOT NULL,
    "fecha_movimiento" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "motivo" TEXT NOT NULL,
    "animal_id" UUID NOT NULL,

    CONSTRAINT "movimientos_pkey" PRIMARY KEY ("id_movimiento")
);

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_rol_id_fkey" FOREIGN KEY ("rol_id") REFERENCES "roles"("id_roles") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_refugio_id_fkey" FOREIGN KEY ("refugio_id") REFERENCES "refugios"("id_refugio") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animales" ADD CONSTRAINT "animales_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animales" ADD CONSTRAINT "animales_refugio_id_fkey" FOREIGN KEY ("refugio_id") REFERENCES "refugios"("id_refugio") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animales"("id_animal") ON DELETE CASCADE ON UPDATE CASCADE;
