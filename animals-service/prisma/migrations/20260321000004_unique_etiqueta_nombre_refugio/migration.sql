ALTER TABLE "etiquetas" ADD CONSTRAINT "etiquetas_nombre_refugio_id_key" 
UNIQUE ("nombre", "refugio_id");