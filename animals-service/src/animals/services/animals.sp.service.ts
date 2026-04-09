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

    const result = await this.prisma.$queryRaw<
      { p_id_animal_creado: string }[]
    >`
      CALL sp_registrar_animal_completo(
        ${dto.nombre}::VARCHAR,
        ${dto.especie}::VARCHAR,
        ${dto.raza}::VARCHAR,
        ${dto.edad}::INTEGER,
        ${dto.peso}::DECIMAL,
        ${dto.sexo}::"sexo_animal",
        ${tamanoDb}::"tamano_lista",
        ${dto.enfermedad_no_tratable}::BOOLEAN,
        ${dto.discapacidad}::BOOLEAN,
        ${dto.es_agresivo}::BOOLEAN,
        ${dto.lugar}::TEXT,
        ${dto.descripcion}::TEXT,
        ${dto.refugio_id}::UUID,
        ${dto.usuario_id}::UUID,
        NULL::UUID,
        ${dto.url_imagen ?? null}::TEXT,
        ${dto.fecha_rescate ? new Date(dto.fecha_rescate) : new Date()}::TIMESTAMP
      )
    `;

    const id = result?.[0]?.p_id_animal_creado;

    if (!id) {
      throw new BadRequestException(
        'El SP no devolvió el ID del animal creado. Verifique los datos enviados.',
      );
    }

    const animal = await this.prisma.animal.findUniqueOrThrow({
      where: { id_animal: id },
      include: {
        imagenes: true,
        etiquetas: { include: { etiqueta: true } },
      },
    });

    return animal;
  }
}
