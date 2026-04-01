/*
  Warnings:

  - A unique constraint covering the columns `[email]` on the table `usuarios` will be added. If there are existing duplicate values, this will fail.
  - Made the column `aceptacion_term` on table `usuarios` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "animales" ALTER COLUMN "createdAt" SET DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "etiquetas" ALTER COLUMN "createdAt" SET DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "movimientos" ALTER COLUMN "createdAt" SET DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "refugios" ALTER COLUMN "createdAt" SET DEFAULT CURRENT_TIMESTAMP;

UPDATE "usuarios" SET "aceptacion_term" = TRUE WHERE "aceptacion_term" IS NULL;

-- AlterTable
ALTER TABLE "usuarios" ALTER COLUMN "createdAt" SET DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "aceptacion_term" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");



CREATE OR REPLACE PROCEDURE sp_crear_refugio_completo(
    p_nombre_refugio VARCHAR(100),
    p_capacidad_max  INTEGER,
    p_estado         VARCHAR(100),
    p_municipio      VARCHAR(100),
    p_colonia        TEXT,
    p_calle          TEXT,
    p_nombre_usuario VARCHAR(100),
    p_apellido_p     VARCHAR(100),
    p_apellido_m     VARCHAR(100),
    p_email          TEXT,
    p_contrasena     TEXT,
    INOUT p_id_refugio UUID DEFAULT NULL,
    INOUT p_id_rol     UUID DEFAULT NULL,
    INOUT p_id_usuario UUID DEFAULT NULL,
    p_num_exterior   INTEGER DEFAULT NULL,
    p_num_interior   INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_email_existe BOOLEAN;
BEGIN
    IF p_capacidad_max <= 0 THEN
        RAISE EXCEPTION
            'La capacidad maxima debe ser mayor a 0. Valor recibido: %.', p_capacidad_max;
    END IF;

    IF p_contrasena IS NULL OR TRIM(p_contrasena) = '' THEN
        RAISE EXCEPTION 'La contrasena no puede estar vacia.';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM usuarios WHERE email = LOWER(TRIM(p_email))
    ) INTO v_email_existe;

    IF v_email_existe THEN
        RAISE EXCEPTION
            'El correo "%" ya esta registrado en el sistema. Use un correo diferente para el propietario.',
            LOWER(TRIM(p_email));
    END IF;

    INSERT INTO refugios (
        nombre, capacidad_max, estado, municipio,
        colonia, calle, num_exterior, num_interior
    )
    VALUES (
        TRIM(p_nombre_refugio),
        p_capacidad_max,
        TRIM(p_estado),
        TRIM(p_municipio),
        TRIM(p_colonia),
        TRIM(p_calle),
        p_num_exterior,
        p_num_interior
    )
    RETURNING id_refugio INTO p_id_refugio;

    INSERT INTO roles (nombre, refugio_id)
    VALUES ('propietario', p_id_refugio)
    RETURNING id_roles INTO p_id_rol;

    INSERT INTO usuarios (
        nombre, apellido_p, apellido_m,
        contrasena, email,
        activo, aceptacion_term,
        rol_id, refugio_id
    )
    VALUES (
        TRIM(p_nombre_usuario),
        TRIM(p_apellido_p),
        TRIM(p_apellido_m),
        p_contrasena,
        LOWER(TRIM(p_email)),
        TRUE,
        TRUE,
        p_id_rol,
        p_id_refugio
    )
    RETURNING id_usuario INTO p_id_usuario;

    RAISE NOTICE
        'Refugio registrado exitosamente: refugio=% | rol=% | usuario=%',
        p_id_refugio, p_id_rol, p_id_usuario;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE
            'Error al crear refugio. Todas las inserciones fueron revertidas. Detalle: %',
            SQLERRM;
        RAISE;
END;
$$;