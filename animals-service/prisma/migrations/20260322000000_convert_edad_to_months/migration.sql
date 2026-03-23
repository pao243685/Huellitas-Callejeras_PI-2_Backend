-- Convertir edad de años a meses para animales registrados en años
UPDATE "animales" SET "edad" = "edad" * 12 WHERE "edad" <= 35;