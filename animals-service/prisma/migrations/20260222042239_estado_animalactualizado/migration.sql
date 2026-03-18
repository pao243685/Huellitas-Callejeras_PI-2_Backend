/*
  Warnings:

  - The values [en_adopcion,en_recuperacion,en_defuncion] on the enum `EstadoAnimal` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "EstadoAnimal_new" AS ENUM ('adoptado', 'adopcion', 'recuperacion', 'defuncion');
ALTER TABLE "animales" ALTER COLUMN "estado" DROP DEFAULT;
ALTER TABLE "animales" ALTER COLUMN "estado" TYPE "EstadoAnimal_new" USING ("estado"::text::"EstadoAnimal_new");
ALTER TYPE "EstadoAnimal" RENAME TO "EstadoAnimal_old";
ALTER TYPE "EstadoAnimal_new" RENAME TO "EstadoAnimal";
DROP TYPE "EstadoAnimal_old";
ALTER TABLE "animales" ALTER COLUMN "estado" SET DEFAULT 'adopcion';
COMMIT;

-- AlterTable
ALTER TABLE "animales" ALTER COLUMN "estado" SET DEFAULT 'adopcion';
