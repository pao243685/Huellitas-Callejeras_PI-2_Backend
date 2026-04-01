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

export interface ResumenRow {
  refugio_id: string;
  nivel_adoptabilidad: string;
  total_animales: number;
  perros: number;
  gatos: number;
  pct_sobre_total: number;
  espacios_en_riesgo: number;
}

export interface AnimalesActivosRow {
  refugio_id: string;
  id_animal: string;
  animal: string;
  especie: string;
  sexo: string;
  tamano: string;
  edad: number;
  enfermedad_no_tratable: boolean;
  discapacidad: boolean;
  es_agresivo: boolean;
  estado: string;
  dias_en_refugio: number;
  fecha_ingreso: Date;
  nivel_adoptabilidad: string;
  nivel_confianza: string;
}

export interface AlertaRow {
  tipo_alerta: string;
  nivel_riesgo: string;
  refugio_id: string;
  id_animal: string;
  animal: string;
  especie: string;
  estado_registro: string;
  fue_devuelto: boolean;
  veces_regresado: number;
  fecha_primer_ingreso: Date | null;
  fecha_ultima_salida: Date | null;
  dias_estancia_actual: number | null;
}
