import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
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

  async validateAnimalPertenece(animalId: string, refugioId: string) {
    const animal = await this.prisma.animal.findUnique({
      where: { id_animal: animalId },
    });
    if (!animal) {
      throw new NotFoundException(`Animal ${animalId} no encontrado`);
    }
    if (animal.refugio_id !== refugioId) {
      throw new ForbiddenException('Este animal no pertenece a tu refugio');
    }
    return animal;
  }
}
