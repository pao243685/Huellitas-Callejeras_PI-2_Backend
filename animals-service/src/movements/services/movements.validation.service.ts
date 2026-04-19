import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
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

  async validateAnimalPertenece(animalId: string, refugioId: string) {
    const animal = await this.validateAnimal(animalId);
    if (animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Ese animal no pertenece a tu refugio');
    }
    return animal;
  }

  async validateMovimientoPertenece(movimientoId: string, refugioId: string) {
    const movimiento = await this.prisma.movimiento.findUnique({
      where: { id_movimiento: movimientoId },
      include: { animal: true },
    });
    if (!movimiento) {
      throw new NotFoundException(`Movimiento ${movimientoId} no encontrado`);
    }
    if (movimiento.animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Ese movimiento no pertenece a tu refugio');
    }
    return movimiento;
  }

  validateMotivoByTipo(tipo: MovimientoTipo, motivo: MovimientoMotivo) {
    const motivosEntrada: MovimientoMotivo[] = [
      MovimientoMotivo.rescate,
      MovimientoMotivo.retorno,
    ];
    const motivosSalida: MovimientoMotivo[] = [
      MovimientoMotivo.adopcion,
      MovimientoMotivo.defuncion,
      MovimientoMotivo.extravio,
    ];

    if (tipo === MovimientoTipo.entrada && !motivosEntrada.includes(motivo)) {
      throw new BadRequestException(
        'Para tipo "entrada" el motivo debe ser: rescate o retorno',
      );
    }
    if (tipo === MovimientoTipo.salida && !motivosSalida.includes(motivo)) {
      throw new BadRequestException(
        'Para tipo "salida" el motivo debe ser: adopcion, defuncion o extravio',
      );
    }
  }

  validateNotFutureDate(fecha: Date, campo = 'fecha_movimiento'): void {
    const now = new Date();
    if (fecha > now) {
      throw new BadRequestException(
        `El campo "${campo}" no puede ser una fecha futura. ` +
          `Valor recibido: ${fecha.toISOString()}. Fecha actual: ${now.toISOString()}.`,
      );
    }
  }

  async validateFechaSecuencial(
    animalId: string,
    nuevaFecha: Date,
    tipo: MovimientoTipo,
  ) {
    this.validateNotFutureDate(nuevaFecha);

    const ultimoMovimiento = await this.prisma.movimiento.findFirst({
      where: { animal_id: animalId },
      orderBy: { fecha_movimiento: 'desc' },
    });

    if (!ultimoMovimiento) return;

    if (nuevaFecha < ultimoMovimiento.fecha_movimiento) {
      const formatDate = (date: Date) => date.toLocaleDateString('es-MX');
      throw new BadRequestException(
        `La fecha del ${tipo === MovimientoTipo.entrada ? 'ingreso' : 'egreso'} (${formatDate(nuevaFecha)}) ` +
          `no puede ser anterior al último movimiento del animal (${formatDate(ultimoMovimiento.fecha_movimiento)}).`,
      );
    }
  }
}
