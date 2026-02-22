import { IsInt, IsOptional, IsString } from 'class-validator';

export class CreateRefugioDto {
  @IsString()
  nombre: string;

  @IsInt()
  capacidad_max: number;

  @IsString()
  estado: string;

  @IsString()
  municipio: string;

  @IsString()
  colonia: string;

  @IsString()
  calle: string;

  @IsOptional()
  @IsInt()
  num_exterior?: number;

  @IsOptional()
  @IsInt()
  num_interior?: number;
}
