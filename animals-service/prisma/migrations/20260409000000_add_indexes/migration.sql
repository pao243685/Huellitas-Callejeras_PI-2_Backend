
CREATE INDEX idx_animales_refugio_id ON animales(refugio_id);
CREATE INDEX idx_animales_usuario_id ON animales(usuario_id);
CREATE INDEX idx_animales_estado ON animales(estado);
CREATE INDEX idx_animales_especie ON animales(especie);
CREATE INDEX idx_animales_nombre ON animales(nombre);
CREATE INDEX idx_usuarios_refugio_id ON usuarios(refugio_id);
CREATE INDEX idx_usuarios_rol_id ON usuarios(rol_id);
CREATE INDEX idx_movimientos_animal_id ON movimientos(animal_id);
CREATE INDEX idx_movimientos_fecha_movimiento ON movimientos(fecha_movimiento);
CREATE INDEX idx_animal_imagen_animal_id ON animal_imagen(animal_id);
CREATE INDEX idx_etiqueta_animal_etiqueta_id ON etiqueta_animal(etiqueta_id);
