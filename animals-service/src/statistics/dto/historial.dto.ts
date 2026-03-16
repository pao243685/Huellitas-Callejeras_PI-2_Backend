import { IsOptional, IsDateString } from 'class-validator';

export class HistorialDto {
  @IsOptional()
  @IsDateString()
  fecha_inicio?: string;

  @IsOptional()
  @IsDateString()
  fecha_fin?: string;
}
