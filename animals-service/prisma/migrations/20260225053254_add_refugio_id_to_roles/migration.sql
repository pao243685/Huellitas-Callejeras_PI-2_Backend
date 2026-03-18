/*
  Warnings:

  - Added the required column `refugio_id` to the `roles` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "animales" DROP CONSTRAINT "animales_usuario_id_fkey";

-- AlterTable
ALTER TABLE "roles" ADD COLUMN "refugio_id" UUID NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "roles" ALTER COLUMN "refugio_id" DROP DEFAULT;

-- AddForeignKey
ALTER TABLE "roles" ADD CONSTRAINT "roles_refugio_id_fkey" FOREIGN KEY ("refugio_id") REFERENCES "refugios"("id_refugio") ON DELETE RESTRICT ON UPDATE CASCADE;
