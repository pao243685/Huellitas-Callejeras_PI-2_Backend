-- AlterTable
ALTER TABLE "animales" ADD COLUMN "createdAt" TIMESTAMP(6) DEFAULT NULL,
ADD COLUMN "updatedAt" TIMESTAMP(6) DEFAULT NULL;

-- AlterTable
ALTER TABLE "movimientos" ADD COLUMN "createdAt" TIMESTAMP(6) DEFAULT NULL,
ADD COLUMN "updatedAt" TIMESTAMP(6) DEFAULT NULL;

-- AlterTable
ALTER TABLE "refugios" ADD COLUMN "createdAt" TIMESTAMP(6) DEFAULT NULL,
ADD COLUMN "updatedAt" TIMESTAMP(6) DEFAULT NULL;

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN "createdAt" TIMESTAMP(6) DEFAULT NULL,
ADD COLUMN "updatedAt" TIMESTAMP(6) DEFAULT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");