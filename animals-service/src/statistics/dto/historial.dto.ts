import { IsDateString, IsEnum } from 'class-validator';

export class HistorialDto {
  @IsDateString()
  fecha_ini: string;

  @IsDateString()
  fecha_fin: string;

  @IsEnum(['semana', 'mes'])
  modo: 'semana' | 'mes';
}
