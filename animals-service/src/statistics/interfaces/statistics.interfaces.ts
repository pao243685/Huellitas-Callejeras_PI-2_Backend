export interface IndicadorRow {
  datos: string;
  historico: string;
  actual: string;
  resultado: string;
}

export interface GraficaRow {
  periodo: string;
  fecha_punto: Date;
  ocupacion_total: number;
  entradas_acum: number;
  salidas_adopcion: number;
  salidas_defuncion: number;
  salidas_extravio: number;
}
