-- Agregar foreign key de animales a usuarios
ALTER TABLE "animales" ADD CONSTRAINT "animales_usuario_id_fkey"
FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id_usuario")
ON DELETE RESTRICT ON UPDATE CASCADE;