import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RegistrarAnimalSpDto } from '../dto/registrar-animal-sp.dto';
import type {
  Animal,
  AnimalImagen,
  EtiquetaAnimal,
  Etiqueta,
} from '@prisma/client';

export interface AnimalConRelaciones extends Animal {
  imagenes: AnimalImagen[];
  etiquetas: (EtiquetaAnimal & { etiqueta: Etiqueta })[];
}

@Injectable()
export class AnimalsSpService {
  constructor(private readonly prisma: PrismaService) {}

  async registrarAnimalCompleto(
    dto: RegistrarAnimalSpDto,
  ): Promise<AnimalConRelaciones> {
    const tamanoMap: Record<string, string> = {
      miniatura: 'miniatura',
      pequeno: 'pequeño',
      mediano: 'mediano',
      grande: 'grande',
      gigante: 'gigante',
    };

    const tamanoDb = tamanoMap[dto.tamano] ?? dto.tamano;
    const estado = dto.estado || 'adopcion';
    const tipoMovimiento = dto.tipo_movimiento || 'entrada';
    const motivo = dto.motivo || 'rescate';
    const fechaMovimiento = dto.fecha_movimiento
      ? new Date(dto.fecha_movimiento)
      : new Date();

    await this.prisma.$executeRawUnsafe(
      `
      CALL sp_registrar_animal_completo(
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
        $13, $14, $15, $16, $17, $18, NULL, $19
      )
    `,
      dto.nombre,
      dto.especie,
      dto.raza,
      dto.edad,
      dto.peso,
      dto.sexo,
      tamanoDb,
      dto.enfermedad_no_tratable,
      dto.discapacidad,
      dto.es_agresivo,
      dto.lugar,
      dto.descripcion,
      dto.usuario_id,
      dto.refugio_id,
      estado,
      tipoMovimiento,
      motivo,
      fechaMovimiento,
      dto.url_imagen ?? null,
    );

    const animal = await this.prisma.animal.findFirst({
      where: {
        usuario_id: dto.usuario_id,
        refugio_id: dto.refugio_id,
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        imagenes: true,
        etiquetas: { include: { etiqueta: true } },
      },
    });

    if (!animal) {
      throw new BadRequestException(
        'El animal no fue creado correctamente. Verifique los datos enviados.',
      );
    }

    return animal;
  }
}
