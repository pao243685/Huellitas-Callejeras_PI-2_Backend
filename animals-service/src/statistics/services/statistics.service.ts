import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { IndicadorRow } from '../interfaces/statistics.interfaces';

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getIndicadores(refugioId: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: refugioId },
    });

    if (!refugio) {
      throw new NotFoundException(`Refugio ${refugioId} no encontrado`);
    }

    const rows = await this.prisma.$queryRaw<IndicadorRow[]>`
      SELECT * FROM get_adoption_profile(${refugioId}::uuid)
    `;

    return {
      refugio_id: refugioId,
      indicadores: rows,
    };
  }
}
