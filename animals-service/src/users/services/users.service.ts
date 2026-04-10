import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { UsersDto } from '../dto/users.dto';
import { UpdateUsersDto } from '../dto/update-users.dto';
import { UsersValidationService } from './usuario.validation.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validation: UsersValidationService,
  ) {}

  async findByRefugio(refugioId: string) {
    await this.validation.validateRefugio(refugioId);
    const users = await this.prisma.usuario.findMany({
      where: { refugio_id: refugioId },
      include: { refugio: true, rol: true },
    });
    return users.map((u) => this.omitPassword(u));
  }

  async findOne(id: string, refugioId: string) {
    const user = await this.prisma.usuario.findUnique({
      where: { id_usuario: id },
      include: { rol: true },
    });
    if (!user) {
      throw new NotFoundException(`Usuario ${id} no encontrado`);
    }
    if (user.refugio_id !== refugioId) {
      throw new ForbiddenException('Este usuario no pertenece a tu refugio');
    }
    return this.omitPassword(user);
  }

  async create(dto: UsersDto) {
    await this.validation.validateRefugio(dto.refugio_id);

    const existingUser = await this.prisma.usuario.findFirst({
      where: { email: dto.email },
    });
    if (existingUser) {
      throw new ConflictException('El email ya está registrado');
    }

    const hashedPassword = await bcrypt.hash(dto.contrasena, 10);

    const newUser = await this.prisma.usuario.create({
      data: {
        nombre: dto.nombre,
        apellido_p: dto.apellido_p,
        apellido_m: dto.apellido_m,
        email: dto.email,
        contrasena: hashedPassword,
        activo: dto.activo,
        aceptacion_term: dto.aceptacion_term ?? false,
        rol_id: dto.rol_id,
        refugio_id: dto.refugio_id,
      },
    });

    return this.omitPassword(newUser);
  }

  async update(id: string, dto: UpdateUsersDto, refugioId: string) {
    const existing = await this.findOne(id, refugioId);

    if (dto.email && dto.email !== existing.email) {
      const emailInUse = await this.prisma.usuario.findFirst({
        where: { email: dto.email },
      });
      if (emailInUse) {
        throw new ConflictException('El email ya está registrado');
      }
    }

    const data: UpdateUsersDto = { ...dto };
    if (dto.contrasena) {
      data.contrasena = await bcrypt.hash(dto.contrasena, 10);
    } else {
      delete data.contrasena;
    }

    const updated = await this.prisma.usuario.update({
      where: { id_usuario: id },
      data,
    });

    return this.omitPassword(updated);
  }

  async delete(id: string, refugioId: string) {
    await this.findOne(id, refugioId);
    await this.prisma.usuario.delete({ where: { id_usuario: id } });
    return { message: 'Usuario eliminado', id };
  }

  private omitPassword<T extends { contrasena: string }>(
    user: T,
  ): Omit<T, 'contrasena'> {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { contrasena: _, ...rest } = user;
    return rest;
  }
}
