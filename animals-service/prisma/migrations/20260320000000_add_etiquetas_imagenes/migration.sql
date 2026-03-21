-- Agregar campo aceptacion_term a usuarios
ALTER TABLE "usuarios" ADD COLUMN "aceptacion_term" BOOLEAN DEFAULT NULL;

-- Crear tabla animal_imagen y migrar datos de imagen
CREATE TABLE "animal_imagen" (
  "id_animal_imagen" UUID NOT NULL DEFAULT gen_random_uuid(),
  "imagen" TEXT NOT NULL,
  "animal_id" UUID NOT NULL,
  CONSTRAINT "animal_imagen_pkey" PRIMARY KEY ("id_animal_imagen")
);

ALTER TABLE "animal_imagen"
  ADD CONSTRAINT "animal_imagen_animal_id_fkey"
  FOREIGN KEY ("animal_id") REFERENCES "animales"("id_animal")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Migrar imágenes existentes a la nueva tabla
INSERT INTO "animal_imagen" ("imagen", "animal_id")
SELECT "imagen", "id_animal" FROM "animales" WHERE "imagen" IS NOT NULL;

-- Eliminar columna imagen de animales
ALTER TABLE "animales" DROP COLUMN "imagen";

-- Crear tabla etiquetas
CREATE TABLE "etiquetas" (
  "id_etiqueta" UUID NOT NULL DEFAULT gen_random_uuid(),
  "nombre" VARCHAR(100) NOT NULL,
  "createdAt" TIMESTAMP(6) DEFAULT NULL,
  "updatedAt" TIMESTAMP(6) DEFAULT NULL,
  CONSTRAINT "etiquetas_pkey" PRIMARY KEY ("id_etiqueta")
);

-- Crear tabla etiqueta_animal
CREATE TABLE "etiqueta_animal" (
  "animal_id" UUID NOT NULL,
  "etiqueta_id" UUID NOT NULL,
  CONSTRAINT "etiqueta_animal_pkey" PRIMARY KEY ("animal_id", "etiqueta_id")
);

ALTER TABLE "etiqueta_animal"
  ADD CONSTRAINT "etiqueta_animal_animal_id_fkey"
  FOREIGN KEY ("animal_id") REFERENCES "animales"("id_animal")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "etiqueta_animal"
  ADD CONSTRAINT "etiqueta_animal_etiqueta_id_fkey"
  FOREIGN KEY ("etiqueta_id") REFERENCES "etiquetas"("id_etiqueta")
  ON DELETE CASCADE ON UPDATE CASCADE;