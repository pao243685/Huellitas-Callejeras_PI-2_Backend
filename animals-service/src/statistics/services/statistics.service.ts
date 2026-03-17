import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { IndicadorRow, GraficaRow } from '../interfaces/statistics.interfaces';

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

  async getHistorial(
    refugioId: string,
    fechaIni: string,
    fechaFin: string,
    modo: 'semana' | 'mes',
  ) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: refugioId },
    });

    if (!refugio) {
      throw new NotFoundException(`Refugio ${refugioId} no encontrado`);
    }

    const rows = await this.prisma.$queryRaw<GraficaRow[]>`
      SELECT * FROM get_movimientos_grafica(
        ${refugioId}::uuid,
        ${new Date(fechaIni)}::timestamp,
        ${new Date(fechaFin)}::timestamp,
        ${modo}::text
      )
    `;

    return {
      refugio_id: refugioId,
      modo,
      fecha_ini: fechaIni,
      fecha_fin: fechaFin,
      datos: rows,
    };
  }
}
