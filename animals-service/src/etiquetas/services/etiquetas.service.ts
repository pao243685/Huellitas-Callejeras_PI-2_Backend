import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateEtiquetaDto } from '../dto/etiqueta.dto';
import { UpdateEtiquetaDto } from '../dto/update-etiqueta.dto';

@Injectable()
export class EtiquetasService {
  constructor(private readonly prisma: PrismaService) {}

  async findByRefugio(refugioId: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: refugioId },
    });
    if (!refugio) {
      throw new NotFoundException(`Refugio ${refugioId} no encontrado`);
    }
    return this.prisma.etiqueta.findMany({
      where: { refugio_id: refugioId },
      orderBy: { nombre: 'asc' },
    });
  }

  async findOne(id: string, refugioId: string) {
    const etiqueta = await this.prisma.etiqueta.findUnique({
      where: { id_etiqueta: id },
      select: {
        id_etiqueta: true,
        nombre: true,
        refugio_id: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!etiqueta) {
      throw new NotFoundException(`Etiqueta ${id} no encontrada`);
    }
    if (etiqueta.refugio_id !== refugioId) {
      throw new ForbiddenException('Esta etiqueta no pertenece a tu refugio');
    }
    return etiqueta;
  }

  async create(dto: CreateEtiquetaDto) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: dto.refugio_id },
    });
    if (!refugio) {
      throw new NotFoundException(`Refugio ${dto.refugio_id} no encontrado`);
    }
    const existe = await this.prisma.etiqueta.findFirst({
      where: {
        nombre: { equals: dto.nombre, mode: 'insensitive' },
        refugio_id: dto.refugio_id,
      },
    });
    if (existe) {
      throw new ConflictException(
        `Ya existe una etiqueta con el nombre "${dto.nombre}" en este refugio`,
      );
    }
    return this.prisma.etiqueta.create({ data: dto });
  }

  async update(id: string, dto: UpdateEtiquetaDto, refugioId: string) {
    await this.findOne(id, refugioId);

    if (dto.nombre) {
      const existing = await this.prisma.etiqueta.findFirst({
        where: {
          nombre: { equals: dto.nombre, mode: 'insensitive' },
          refugio_id: refugioId,
          NOT: { id_etiqueta: id },
        },
      });
      if (existing) {
        throw new ConflictException(
          `Ya existe una etiqueta con el nombre "${dto.nombre}" en este refugio`,
        );
      }
    }

    return this.prisma.etiqueta.update({
      where: { id_etiqueta: id },
      data: dto,
    });
  }

  async delete(id: string, refugioId: string) {
    await this.findOne(id, refugioId);
    await this.prisma.etiqueta.delete({ where: { id_etiqueta: id } });
    return { message: 'Etiqueta eliminada', id };
  }

  async asignarAAnimal(
    animalId: string,
    etiquetaId: string,
    refugioId: string,
  ) {
    const animal = await this.prisma.animal.findUnique({
      where: { id_animal: animalId },
    });
    if (!animal) {
      throw new NotFoundException(`Animal ${animalId} no encontrado`);
    }
    if (animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Este animal no pertenece a tu refugio');
    }

    const etiqueta = await this.prisma.etiqueta.findUnique({
      where: { id_etiqueta: etiquetaId },
    });
    if (!etiqueta) {
      throw new NotFoundException(`Etiqueta ${etiquetaId} no encontrada`);
    }
    if (etiqueta.refugio_id !== refugioId) {
      throw new ForbiddenException('Esta etiqueta no pertenece a tu refugio');
    }

    await this.prisma.etiquetaAnimal.upsert({
      where: {
        animal_id_etiqueta_id: { animal_id: animalId, etiqueta_id: etiquetaId },
      },
      create: { animal_id: animalId, etiqueta_id: etiquetaId },
      update: {},
    });

    return this.prisma.animal.findUnique({
      where: { id_animal: animalId },
      include: { etiquetas: { include: { etiqueta: true } } },
    });
  }

  async quitarDeAnimal(
    animalId: string,
    etiquetaId: string,
    refugioId: string,
  ) {
    const animal = await this.prisma.animal.findUnique({
      where: { id_animal: animalId },
    });
    if (!animal) {
      throw new NotFoundException(`Animal ${animalId} no encontrado`);
    }
    if (animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Este animal no pertenece a tu refugio');
    }

    const relacion = await this.prisma.etiquetaAnimal.findUnique({
      where: {
        animal_id_etiqueta_id: { animal_id: animalId, etiqueta_id: etiquetaId },
      },
    });
    if (!relacion) {
      throw new NotFoundException(
        `El animal ${animalId} no tiene asignada la etiqueta ${etiquetaId}`,
      );
    }

    await this.prisma.etiquetaAnimal.delete({
      where: {
        animal_id_etiqueta_id: { animal_id: animalId, etiqueta_id: etiquetaId },
      },
    });

    return { message: 'Etiqueta quitada del animal', animalId, etiquetaId };
  }
}
