import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
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
}
