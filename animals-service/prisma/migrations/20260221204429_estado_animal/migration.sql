-- CreateEnum
CREATE TYPE "EstadoAnimal" AS ENUM ('adoptado', 'en_adopcion', 'en_recuperacion', 'en_defuncion');

-- AlterTable
ALTER TABLE "animales" ADD COLUMN     "estado" "EstadoAnimal" NOT NULL DEFAULT 'en_adopcion';
