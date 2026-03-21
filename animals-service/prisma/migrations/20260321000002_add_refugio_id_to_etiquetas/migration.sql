-- Agregar refugio_id a etiquetas
ALTER TABLE "etiquetas" ADD COLUMN "refugio_id" UUID NOT NULL DEFAULT gen_random_uuid();

-- Quitar el DEFAULT temporal
ALTER TABLE "etiquetas" ALTER COLUMN "refugio_id" DROP DEFAULT;

-- Agregar FK a refugios
ALTER TABLE "etiquetas"
  ADD CONSTRAINT "etiquetas_refugio_id_fkey"
  FOREIGN KEY ("refugio_id") REFERENCES "refugios"("id_refugio")
  ON DELETE CASCADE ON UPDATE CASCADE;