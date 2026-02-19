/* eslint-disable */
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { MovementsValidationService } from './movements.validation.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { UpdateMovementDto } from '../dto/update-movement.dto';

@Injectable()
export class MovementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: MovementsValidationService,
  ) {}

  async findAll() {
    return this.prisma.movimiento.findMany({
      include: { animal: true },
      orderBy: { fecha_movimiento: 'desc' },
    });
  }

  async findOne(id: string) {
    const movimiento = await this.prisma.movimiento.findUnique({
      where: { id_movimiento: id },
      include: { animal: true },
    });

    if (!movimiento) {
      throw new NotFoundException(`Movimiento ${id} no encontrado`);
    }

    return movimiento;
  }

  async findByAnimal(animalId: string) {
    await this.validation.validateAnimal(animalId);

    return this.prisma.movimiento.findMany({
      where: { animal_id: animalId },
      include: { animal: true },
      orderBy: { fecha_movimiento: 'desc' },
    });
  }

  async create(dto: CreateMovementDto) {
    await this.validation.validateAnimal(dto.animal_id);
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

  async update(id: string, dto: UpdateMovementDto) {
    const existing = await this.prisma.movimiento.findUnique({
      where: { id_movimiento: id },
    });

    if (!existing) {
      throw new NotFoundException(`Movimiento ${id} no encontrado`);
    }

    const tipoFinal = dto.tipo_movimiento ?? existing.tipo_movimiento;
    const motivoFinal = dto.motivo ?? existing.motivo;

    this.validation.validateMotivoByTipo(tipoFinal, motivoFinal);

    return this.prisma.movimiento.update({
      where: { id_movimiento: id },
      data: {
        ...(dto.tipo_movimiento && { tipo_movimiento: dto.tipo_movimiento }),
        ...(dto.motivo && { motivo: dto.motivo }),
        ...(dto.fecha_movimiento && {
          fecha_movimiento: new Date(dto.fecha_movimiento),
        }),
      },
      include: { animal: true },
    });
  }

  async delete(id: string) {
    const movimiento = await this.prisma.movimiento.findUnique({
      where: { id_movimiento: id },
    });

    if (!movimiento) {
      throw new NotFoundException(`Movimiento ${id} no encontrado`);
    }

    await this.prisma.movimiento.delete({ where: { id_movimiento: id } });

    return { message: 'Movimiento eliminado', id };
  }
}