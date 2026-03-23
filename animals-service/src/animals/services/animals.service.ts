import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { AnimalsValidationService } from './animals.validation.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';

@Injectable()
export class AnimalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: AnimalsValidationService,
  ) {}

  private toMeses(edad: number, unidad?: 'meses' | 'años'): number {
    return unidad === 'años' ? edad * 12 : edad;
  }

  async findByRefugio(refugioId: string, page = 1, limit = 10) {
    await this.validation.validateRefugio(refugioId);

    const skip = (page - 1) * limit;

    const [data, total] = await this.prisma.$transaction([
      this.prisma.animal.findMany({
        where: { refugio_id: refugioId },
        include: {
          refugio: true,
          imagenes: true,
          etiquetas: { include: { etiqueta: true } },
        },
        skip,
        take: limit,
        orderBy: { nombre: 'asc' },
      }),
      this.prisma.animal.count({
        where: { refugio_id: refugioId },
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
        hasPrevPage: page > 1,
      },
    };
  }

  async findOne(id: string, refugioId: string) {
    await this.validation.validateAnimalPertenece(id, refugioId);
    return this.prisma.animal.findUnique({
      where: { id_animal: id },
      include: {
        imagenes: true,
        etiquetas: { include: { etiqueta: true } },
      },
    });
  }

  async create(dto: CreateAnimalDto) {
    await this.validation.validateRefugio(dto.refugio_id);
    await this.validation.validateUsuario(dto.usuario_id);

    const edadEnMeses = this.toMeses(dto.edad, dto.unidad_edad);

    return this.prisma.animal.create({
      data: {
        nombre: dto.nombre,
        estado: dto.estado,
        especie: dto.especie,
        raza: dto.raza,
        edad: edadEnMeses,
        peso: dto.peso,
        sexo: dto.sexo,
        tamano: dto.tamano,
        enfermedad_no_tratable: dto.enfermedad_no_tratable,
        discapacidad: dto.discapacidad,
        es_agresivo: dto.es_agresivo,
        lugar: dto.lugar,
        descripcion: dto.descripcion,
        refugio_id: dto.refugio_id,
        usuario_id: dto.usuario_id,
        ...(dto.imagen && {
          imagenes: { create: { imagen: dto.imagen } },
        }),
      },
      include: {
        imagenes: true,
        etiquetas: { include: { etiqueta: true } },
      },
    });
  }

  async update(id: string, dto: UpdateAnimalDto, refugioId: string) {
    await this.validation.validateAnimalPertenece(id, refugioId);

    if (dto.refugio_id) {
      await this.validation.validateRefugio(dto.refugio_id);
    }
    if (dto.usuario_id) {
      await this.validation.validateUsuario(dto.usuario_id);
    }

    const { imagen, unidad_edad, ...dataSinImagen } = dto;

    const dataParaActualizar = { ...dataSinImagen };
    if (dataParaActualizar.edad !== undefined) {
      dataParaActualizar.edad = this.toMeses(
        dataParaActualizar.edad,
        unidad_edad,
      );
    }

    const animal = await this.prisma.animal.update({
      where: { id_animal: id },
      data: dataParaActualizar,
      include: {
        imagenes: true,
        etiquetas: { include: { etiqueta: true } },
      },
    });

    if (imagen) {
      await this.prisma.animalImagen.create({
        data: { imagen, animal_id: id },
      });
      return this.prisma.animal.findUnique({
        where: { id_animal: id },
        include: {
          imagenes: true,
          etiquetas: { include: { etiqueta: true } },
        },
      });
    }

    return animal;
  }

  async deleteImagen(imagenId: string, refugioId: string) {
    const img = await this.prisma.animalImagen.findUnique({
      where: { id_animal_imagen: imagenId },
      include: { animal: true },
    });
    if (!img) {
      throw new NotFoundException(`Imagen ${imagenId} no encontrada`);
    }
    if (img.animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Esta imagen no pertenece a tu refugio');
    }
    await this.prisma.animalImagen.delete({
      where: { id_animal_imagen: imagenId },
    });
    return { message: 'Imagen eliminada', id: imagenId };
  }

  async delete(id: string, refugioId: string) {
    await this.validation.validateAnimalPertenece(id, refugioId);
    await this.prisma.animal.delete({ where: { id_animal: id } });
    return { message: 'Animal eliminado', id };
  }
}
