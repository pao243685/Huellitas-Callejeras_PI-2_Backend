import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateAnimalDto } from 'src/animals/dto/create-animal.dto';

@Injectable()
export class AnimalsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.usuario.findMany();
  }

  async findOne(id: string) {
    const animal = await this.prisma.usuario.findUnique({
      where: { id_usuario: id },
    });

    if (!animal) {
      throw new NotFoundException(`Animal ${id} no encontrado`);
    }

    return animal;
  }

  async create(dto: CreateDto) {
    await this.validation.validateRefugio(dto.refugio_id);
    await this.validation.validateUsuario(dto.usuario_id);

    const animal = await this.prisma.animal.create({
      data: {
        nombre: dto.nombre,
        especie: dto.especie,
        raza: dto.raza,
        edad: dto.edad,
        peso: dto.peso,
        sexo: dto.sexo,
        imagen: dto.imagen,
        tamano: dto.tamano,
        enfermedad_no_tratable: dto.enfermedad_no_tratable,
        discapacidad: dto.discapacidad,
        es_agresivo: dto.es_agresivo,
        lugar: dto.lugar,
        descripcion: dto.descripcion,
        refugio_id: dto.refugio_id,
        usuario_id: dto.usuario_id,
      },
    });

    return animal;
  }

  async update(id: string, dto: UpdateAnimalDto) {
    const existing = await this.prisma.animal.findUnique({
      where: { id_animal: id },
    });

    if (!existing) {
      throw new NotFoundException(`Animal ${id} no encontrado`);
    }

    if (dto.refugio_id) {
      await this.validation.validateRefugio(dto.refugio_id);
    }

    if (dto.usuario_id) {
      await this.validation.validateUsuario(dto.usuario_id);
    }

    const animal = await this.prisma.animal.update({
      where: { id_animal: id },
      data: dto,
    });

    return animal;
  }

  async delete(id: string) {
    const animal = await this.prisma.animal.findUnique({
      where: { id_animal: id },
    });

    if (!animal) {
      throw new NotFoundException(`Animal ${id} no encontrado`);
    }

    await this.prisma.animal.delete({ where: { id_animal: id } });

    return { message: 'Animal eliminado', id };
  }
}
