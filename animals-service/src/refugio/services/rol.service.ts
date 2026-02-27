import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/shared/prisma/prisma.service';
import { CreateRolDto } from '../dto/create-rol.dto';
import { UpdateRolDto } from '../dto/update-rol.dto';
import { RolValidationService } from './rol.validate.service';

@Injectable()
export class RolService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: RolValidationService,
  ) {}

  async findByrefugio(refugioId: string) {
    await this.validation.validateRefugio(refugioId);

    return this.prisma.rol.findMany({
      where: { refugio_id: refugioId },
      include: { refugio: true },
    });
  }

  async findOne(id: string) {
    const refugio = await this.prisma.rol.findUnique({
      where: { id_roles: id },
    });

    if (!refugio) {
      throw new NotFoundException(`Rol ${id} no encontrado`);
    }

    return refugio;
  }

  async create(dto: CreateRolDto) {
    const refugio = await this.prisma.rol.create({
      data: dto,
    });

    return refugio;
  }

  async update(id: string, dto: UpdateRolDto) {
    const existing = await this.prisma.rol.findUnique({
      where: { id_roles: id },
    });

    if (!existing) {
      throw new NotFoundException(`Rol ${id} no encontrado`);
    }

    const refugio = await this.prisma.rol.update({
      where: { id_roles: id },
      data: dto,
    });

    return refugio;
  }

  async delete(id: string) {
    const animal = await this.prisma.rol.findUnique({
      where: { id_roles: id },
    });

    if (!animal) {
      throw new NotFoundException(`Rol ${id} no encontrado`);
    }

    await this.prisma.rol.delete({ where: { id_roles: id } });

    return { message: 'Rol   eliminado', id };
  }
}
