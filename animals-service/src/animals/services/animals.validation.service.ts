import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';

@Injectable()
export class AnimalsValidationService {
  constructor(private readonly prisma: PrismaService) {}

  async validateRefugio(refugioId: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: refugioId },
    });

    if (!refugio) {
      throw new NotFoundException(`Refugio ${refugioId} no existe`);
    }
  }

  async validateUsuario(usuarioId: string) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { id_usuario: usuarioId },
    });

    if (!usuario) {
      throw new NotFoundException(`Usuario ${usuarioId} no existe`);
    }
  }
}
