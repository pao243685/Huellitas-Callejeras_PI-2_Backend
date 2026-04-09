import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RegistrarAnimalSpDto } from '../dto/registrar-animal-sp.dto';

@Injectable()
export class AnimalsSpService {
  constructor(private readonly prisma: PrismaService) {}

  async registrarAnimalCompleto(
    dto: RegistrarAnimalSpDto,
  ): Promise<{ id_animal_creado: string }> {
    // Map TypeScript enum values to DB enum values with proper casing/diacritics
    const tamanoMap = {
      miniatura: 'miniatura',
      pequeno: 'pequeño',  // DB expects "pequeño" with tilde
      mediano: 'mediano',
      grande: 'grande',
      gigante: 'gigante',
    };

    const tamanoDb = tamanoMap[dto.tamano] || dto.tamano;

    const result = await this.prisma.$queryRaw<{ p_id_animal_creado: string }[]>`
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
        ${dto.usuario_id}::UUID,
        ${dto.refugio_id}::UUID,
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

    return { id_animal_creado: id };
  }
}