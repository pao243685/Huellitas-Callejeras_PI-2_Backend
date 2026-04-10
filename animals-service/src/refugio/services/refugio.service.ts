import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';

@Injectable()
export class RefugioService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.refugio.findMany();
  }

  async findOne(id: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: id },
    });

    if (!refugio) {
      throw new NotFoundException(`Refugio ${id} no encontrado`);
    }

    return refugio;
  }

  async update(id: string, dto: UpdateRefugioDto) {
    const existing = await this.prisma.refugio.findUnique({
      where: { id_refugio: id },
    });

    if (!existing) {
      throw new NotFoundException(`Refugio ${id} no encontrado`);
    }

    const refugio = await this.prisma.refugio.update({
      where: { id_refugio: id },
      data: dto,
    });

    return refugio;
  }

  async delete(id: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: id },
    });

    if (!refugio) {
      throw new NotFoundException(`Refugio ${id} no encontrado`);
    }

    await this.prisma.refugio.delete({ where: { id_refugio: id } });

    return { message: 'Refugio eliminado', id };
  }
}
