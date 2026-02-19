/* eslint-disable */
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { MovimientoTipo, MovimientoMotivo } from '@prisma/client';

@Injectable()
export class MovementsValidationService {
  constructor(private readonly prisma: PrismaService) {}

  async validateAnimal(animalId: string) {
    const animal = await this.prisma.animal.findUnique({
      where: { id_animal: animalId },
    });

    if (!animal) {
      throw new NotFoundException(`Animal ${animalId} no existe`);
    }

    return animal;
  }

  validateMotivoByTipo(tipo: MovimientoTipo, motivo: MovimientoMotivo) {
    const motivosEntrada : MovimientoMotivo[] = [MovimientoMotivo.rescate, MovimientoMotivo.retorno];
    const motivosSalida : MovimientoMotivo[] = [MovimientoMotivo.adopcion, MovimientoMotivo.defuncion];

    if (tipo === MovimientoTipo.entrada && !motivosEntrada.includes(motivo)) {
      throw new BadRequestException(
        `Para tipo "entrada" el motivo debe ser: rescate o retorno`,
      );
    }

    if (tipo === MovimientoTipo.salida && !motivosSalida.includes(motivo)) {
      throw new BadRequestException(
        `Para tipo "salida" el motivo debe ser: adopcion o defuncion`,
      );
    }
  }
}