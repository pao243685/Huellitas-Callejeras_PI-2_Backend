import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { UsersDto } from '../dto/users.dto';
import { UpdateUsersDto } from '../dto/update-users.dto';
import { UsersValidationService } from './usuario.validation.service';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: UsersValidationService,
  ) {}

  async findAll() {
    return this.prisma.usuario.findMany();
  }

  async findOne(id: string) {
    const user = await this.prisma.usuario.findUnique({
      where: { id_usuario: id },
    });

    if (!user) {
      throw new NotFoundException(`Usuario ${id} no encontrado`);
    }

    return user;
  }

  async create(dto: UsersDto) {
    await this.validation.validateRefugio(dto.refugio_id);

    const user = await this.prisma.usuario.create({
      data: {
        nombre: dto.nombre,
        apellido_p: dto.apellido_p,
        apellido_m: dto.apellido_m,
        email: dto.email,
        contrasena: dto.contrasena,
        activo: dto.activo,
        rol_id: dto.rol_id,
        refugio_id: dto.refugio_id,
      },
    });

    return user;
  }

  async update(id: string, dto: UpdateUsersDto) {
    const existing = await this.prisma.usuario.findUnique({
      where: { id_usuario: id },
    });

    if (!existing) {
      throw new NotFoundException(`Usuario ${id} no encontrado`);
    }

    const usuario = await this.prisma.usuario.update({
      where: { id_usuario: id },
      data: dto,
    });

    return usuario;
  }

  async delete(id: string) {
    const animal = await this.prisma.usuario.findUnique({
      where: { id_usuario: id },
    });

    if (!animal) {
      throw new NotFoundException(`Usuario ${id} no encontrado`);
    }

    await this.prisma.usuario.delete({ where: { id_usuario: id } });

    return { message: 'Usuario eliminado', id };
  }
}
