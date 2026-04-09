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
    const fechaMovimiento = dto.fecha_movimiento
      ? new Date(dto.fecha_movimiento)
      : new Date();

    await this.prisma.$queryRaw`
      SELECT sp_registrar_animal_completo(
        ${dto.nombre}::VARCHAR(100),
        ${dto.especie}::VARCHAR(100),
        ${dto.raza}::VARCHAR(100),
        ${dto.edad}::INTEGER,
        ${dto.peso}::DECIMAL(10,2),
        ${dto.sexo}::TEXT,
        ${tamanoDb}::TEXT,
        ${dto.enfermedad_no_tratable}::BOOLEAN,
        ${dto.discapacidad}::BOOLEAN,
        ${dto.es_agresivo}::BOOLEAN,
        ${dto.lugar}::TEXT,
        ${dto.descripcion}::TEXT,
        ${dto.refugio_id}::UUID,
        ${dto.usuario_id}::UUID,
        ${dto.url_imagen}::TEXT,
        ${fechaMovimiento}::TIMESTAMP
      )
    `;

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
