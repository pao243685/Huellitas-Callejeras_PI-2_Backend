import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { MovementsValidationService } from './movements.validation.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { MovimientoMotivo } from '@prisma/client';

@Injectable()
export class MovementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: MovementsValidationService,
  ) {}

  async findAll(refugioId: string) {
    return this.prisma.movimiento.findMany({
      where: { animal: { refugio_id: refugioId } },
      include: { animal: true },
      orderBy: { fecha_movimiento: 'desc' },
    });
  }

  async findOne(id: string, refugioId: string) {
    return this.validation.validateMovimientoPertenece(id, refugioId);
  }

  async findByAnimal(animalId: string, refugioId: string) {
    await this.validation.validateAnimalPertenece(animalId, refugioId);

    return this.prisma.movimiento.findMany({
      where: { animal_id: animalId },
      include: { animal: true },
      orderBy: { fecha_movimiento: 'desc' },
    });
  }

  async create(dto: CreateMovementDto, refugioId: string) {
    await this.validation.validateAnimalPertenece(dto.animal_id, refugioId);
    this.validation.validateMotivoByTipo(dto.tipo_movimiento, dto.motivo);

    return this.prisma.movimiento.create({
      data: {
        tipo_movimiento: dto.tipo_movimiento,
        motivo: dto.motivo,
        ...(dto.fecha_movimiento && {
          fecha_movimiento: new Date(dto.fecha_movimiento),
        }),
        animal_id: dto.animal_id,
      },
      include: { animal: true },
    });
  }

  async delete(id: string, refugioId: string) {
    const movimiento = await this.validation.validateMovimientoPertenece(
      id,
      refugioId,
    );

    if (movimiento.motivo === MovimientoMotivo.defuncion) {
      throw new BadRequestException(
        'No se puede eliminar un movimiento de defunción. Este registro es permanente.',
      );
    }

    await this.prisma.movimiento.delete({ where: { id_movimiento: id } });
    return { message: 'Movimiento eliminado', id };
  }
}
