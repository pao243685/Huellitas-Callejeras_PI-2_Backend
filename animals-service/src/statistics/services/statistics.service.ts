import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import {
  IndicadorRow,
  GraficaRow,
  ResumenRow,
  AlertaRow,
  AnimalesActivosRow,
} from '../interfaces/statistics.interfaces';

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  private serializeBigInt<T>(rows: T[]): T[] {
    return JSON.parse(
      JSON.stringify(rows, (_: string, value: unknown) =>
        typeof value === 'bigint' ? Number(value) : value,
      ),
    ) as T[];
  }

  private async validateRefugio(refugioId: string) {
    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: refugioId },
    });
    if (!refugio) {
      throw new NotFoundException(`Refugio ${refugioId} no encontrado`);
    }
    return refugio;
  }

  async getIndicadores(refugioId: string) {
    const refugio = await this.validateRefugio(refugioId);

    const indicadores = this.serializeBigInt(
      await this.prisma.$queryRaw<IndicadorRow[]>`
        SELECT * FROM get_adoption_profile(${refugioId}::uuid)
      `,
    );

    const resumenRows = this.serializeBigInt(
      await this.prisma.$queryRaw<ResumenRow[]>`
        SELECT *
        FROM vw_resumen_adoptabilidad
        WHERE refugio_id = ${refugioId}::uuid
      `,
    );

    const alertas = this.serializeBigInt(
      await this.prisma.$queryRaw<AlertaRow[]>`
        SELECT *
        FROM vw_alertas_movimientos_no_adopcion
        WHERE refugio_id = ${refugioId}::uuid
      `,
    ).filter((alerta) => alerta.tipo_alerta !== 'Sin alertas');

    const veredicto = this.calcularVeredicto(
      resumenRows,
      refugio.capacidad_max,
      alertas,
    );

    return {
      refugio_id: refugioId,
      refugio_nombre: refugio.nombre,
      capacidad_max: refugio.capacidad_max,
      indicadores,
      veredicto,
      alertas,
    };
  }

  private calcularVeredicto(
    resumenRows: ResumenRow[],
    capacidadMax: number,
    alertas: AlertaRow[],
  ) {
    const totalActivos = resumenRows.reduce(
      (sum, r) => sum + Number(r.total_animales),
      0,
    );
    const espaciosEnRiesgo = resumenRows.reduce(
      (sum, r) => sum + Number(r.espacios_en_riesgo),
      0,
    );
    const espaciosLibres = capacidadMax - totalActivos;
    const pctOcupacion =
      capacidadMax > 0 ? Math.round((totalActivos / capacidadMax) * 100) : 0;
    const alertasAlto = alertas.filter((a) => a.nivel_riesgo === 'Alto').length;
    const alertasMedio = alertas.filter(
      (a) => a.nivel_riesgo === 'Medio',
    ).length;

    let puede: boolean;
    let mensaje: string;
    let tipo: 'positivo' | 'advertencia' | 'negativo';

    if (espaciosLibres <= 0) {
      puede = false;
      tipo = 'negativo';
      mensaje = `El refugio ha alcanzado su capacidad máxima (${capacidadMax} espacios). No puede recibir nuevos animales hasta que se liberen lugares.`;
    } else if (pctOcupacion >= 80) {
      puede = false;
      tipo = 'advertencia';
      mensaje = `El refugio está al ${pctOcupacion}% de su capacidad. Quedan solo ${espaciosLibres} espacios disponibles. Se recomienda no recibir más animales hasta que se registren adopciones.`;
    } else if (espaciosEnRiesgo > totalActivos * 0.5) {
      puede = true;
      tipo = 'advertencia';
      mensaje = `El refugio tiene ${espaciosLibres} espacios libres, pero más de la mitad de sus animales activos tienen baja probabilidad de adopción pronta (${espaciosEnRiesgo} en riesgo). Considerar con cautela.`;
    } else {
      puede = true;
      tipo = 'positivo';
      const prontoAdoptados = totalActivos - espaciosEnRiesgo;
      mensaje = `El refugio puede recibir nuevos animales. Tiene ${espaciosLibres} espacios disponibles y se estima que ${prontoAdoptados} de sus ${totalActivos} animales activos liberarán espacio en el corto plazo.`;
    }

    return {
      puede_recibir: puede,
      tipo,
      mensaje,
      kpis: {
        total_activos: totalActivos,
        espacios_libres: espaciosLibres,
        espacios_en_riesgo: espaciosEnRiesgo,
        pct_ocupacion: pctOcupacion,
        alertas_alto: alertasAlto,
        alertas_medio: alertasMedio,
      },
    };
  }

  async getHistorial(
    refugioId: string,
    fechaIni: string,
    fechaFin: string,
    modo: 'semana' | 'mes',
  ) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const refugio = await this.validateRefugio(refugioId);

    const rows = this.serializeBigInt(
      await this.prisma.$queryRaw<GraficaRow[]>`
        SELECT * FROM get_movimientos_grafica(
          ${refugioId}::uuid,
          ${new Date(fechaIni)}::timestamp,
          ${new Date(fechaFin)}::timestamp,
          ${modo}::text
        )
      `,
    );

    return {
      refugio_id: refugioId,
      modo,
      fecha_ini: fechaIni,
      fecha_fin: fechaFin,
      datos: rows,
    };
  }

  async getAnimalesActivos(refugioId: string) {
    const refugio = await this.validateRefugio(refugioId);

    const animales = this.serializeBigInt(
      await this.prisma.$queryRaw<AnimalesActivosRow[]>`
        SELECT *
        FROM vw_animales_activos
        WHERE refugio_id = ${refugioId}::uuid
        ORDER BY dias_en_refugio DESC
      `,
    );

    const animalesConEdadEnAnios = animales.map((animal) => ({
      ...animal,
      edad: Math.floor(animal.edad / 12),
    }));

    return {
      refugio_id: refugioId,
      refugio_nombre: refugio.nombre,
      total_activos: animalesConEdadEnAnios.length,
      animales: animalesConEdadEnAnios,
    };
  }
}
