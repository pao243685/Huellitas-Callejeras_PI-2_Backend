/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable prettier/prettier */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
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
    console.log('=== DEBUG: INICIO registrarAnimalCompleto ===');
    console.log('Parámetros recibidos:', JSON.stringify(dto, null, 2));

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

    console.log('Tamano mapeado:', tamanoDb);
    console.log('Fecha movimiento:', fechaMovimiento);

    try {
      const result = await this.prisma.$queryRaw<any[]>`
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
          ${dto.estado}::TEXT,
          ${dto.url_imagen}::TEXT,
          ${fechaMovimiento}::TIMESTAMP
        ) as id
      `;

      console.log('Resultado de la consulta:', JSON.stringify(result, null, 2));
      console.log('¿Resultado es array?', Array.isArray(result));
      console.log('Primer elemento:', result[0]);
      console.log('Propiedades del primer elemento:', result[0] ? Object.keys(result[0]) : 'No hay resultado');

      const animalId = result[0]?.id;
      console.log('ID extraído:', animalId);

      if (!animalId) {
        throw new BadRequestException('No se pudo obtener el ID del animal creado');
      }

      const animal = await this.prisma.animal.findUnique({
        where: { id_animal: animalId },
        include: {
          imagenes: true,
          etiquetas: { include: { etiqueta: true } },
        },
      });

      console.log('Animal encontrado:', animal ? animal.id_animal : 'NO ENCONTRADO');

      if (!animal) {
        throw new BadRequestException('Animal no encontrado después de crear');
      }

      console.log('=== DEBUG: FIN OK ===');
      return animal;
    } catch (error) {
      console.error('=== DEBUG: ERROR ===');
      console.error('Error:', error);
      throw error;
    }
  }
}
