import { IsUUID, IsEnum, IsOptional, IsString } from 'class-validator';
import { MovimientoTipo, MovimientoMotivo } from '@prisma/client';

export class CreateMovementDto {
  @IsEnum(MovimientoTipo)
  tipo_movimiento: MovimientoTipo;

  @IsEnum(MovimientoMotivo)
  motivo: MovimientoMotivo;

  @IsOptional()
  @IsString()
  fecha_movimiento?: string;

  @IsUUID()
  animal_id: string;
}
