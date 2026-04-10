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

    
    let animalId;
    await this.prisma.$executeRaw`
      CALL sp_registrar_animal_completo(
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
        ${animalId}::UUID,
        ${dto.url_imagen ? dto.url_imagen : null}::TEXT,
        ${fechaMovimiento}::TIMESTAMP
      )
    `;
  
    const result = await this.prisma.animal.findFirst({
      where: {
        nombre: dto.nombre,
        refugio_id: dto.refugio_id
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    animalId = result?.id_animal;

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

    if (!animal) {
      throw new BadRequestException('Animal no encontrado después de crear');
    }

    return animal;
  }
}
