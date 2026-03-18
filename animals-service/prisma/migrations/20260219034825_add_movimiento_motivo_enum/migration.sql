/*
  Warnings:

  - The values [rescate,retorno,adopcion,defuncion] on the enum `movimiento_tipo` will be removed. If these variants are still used in the database, this will fail.
  - Changed the type of `motivo` on the `movimientos` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "movimiento_motivo" AS ENUM ('rescate', 'retorno', 'adopcion', 'defuncion');

-- AlterEnum
BEGIN;
CREATE TYPE "movimiento_tipo_new" AS ENUM ('entrada', 'salida');
ALTER TABLE "movimientos" ALTER COLUMN "tipo_movimiento" TYPE "movimiento_tipo_new" USING ("tipo_movimiento"::text::"movimiento_tipo_new");
ALTER TYPE "movimiento_tipo" RENAME TO "movimiento_tipo_old";
ALTER TYPE "movimiento_tipo_new" RENAME TO "movimiento_tipo";
DROP TYPE "movimiento_tipo_old";
COMMIT;

-- AlterTable
ALTER TABLE "movimientos" DROP COLUMN "motivo",
ADD COLUMN     "motivo" "movimiento_motivo" NOT NULL;
