import {
  IsString,
  IsUUID,
  IsInt,
  IsBoolean,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  Min,
  MaxLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { TamanoLista, SexoAnimal } from '@prisma/client';

const toBoolean = ({ value }: { value: unknown }): boolean => {
  if (value === true || value === 1) return true;
  if (value === false || value === 0) return false;
  if (typeof value === 'string') {
    return value.trim().toLowerCase() === 'true' || value.trim() === '1';
  }
  return false;
};

export class RegistrarAnimalSpDto {
  @ApiProperty({ example: 'Rex', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  nombre!: string;

  @ApiProperty({ example: 'Perro', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  especie!: string;

  @ApiProperty({ example: 'Labrador', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  raza!: string;

  @ApiProperty({ example: 24, description: 'Edad en meses' })
  @IsInt()
  @Min(0)
  @Transform(({ value }) => parseInt(value, 10))
  edad!: number;

  @ApiProperty({ example: 15.5 })
  @IsNumber()
  @Min(0)
  @Transform(({ value }) => parseFloat(value))
  peso!: number;

  @ApiProperty({ enum: SexoAnimal, example: SexoAnimal.Macho })
  @IsEnum(SexoAnimal)
  sexo!: SexoAnimal;

  @ApiProperty({ enum: TamanoLista, example: TamanoLista.mediano })
  @IsEnum(TamanoLista)
  tamano!: TamanoLista;

  @ApiProperty({ example: false })
  @IsBoolean()
  @Transform(toBoolean)
  enfermedad_no_tratable!: boolean;

  @ApiProperty({ example: false })
  @IsBoolean()
  @Transform(toBoolean)
  discapacidad!: boolean;

  @ApiProperty({ example: false })
  @IsBoolean()
  @Transform(toBoolean)
  es_agresivo!: boolean;

  @ApiProperty({ example: 'Colonia Centro, Guadalajara' })
  @IsString()
  lugar!: string;

  @ApiProperty({
    example: 'Encontrado en la vía pública, buen estado general.',
  })
  @IsString()
  descripcion!: string;

  @ApiProperty({
    example: 'b1c2d3e4-0000-0000-0000-000000000005',
    format: 'uuid',
    description: 'UUID del usuario que registra el animal',
  })
  @IsUUID()
  usuario_id!: string;

  @ApiProperty({
    example: 'b1c2d3e4-0000-0000-0000-000000000001',
    format: 'uuid',
  })
  @IsUUID()
  refugio_id!: string;

  @ApiProperty({ enum: ['adopcion', 'recuperacion'], example: 'adopcion' })
  @IsEnum(['adopcion', 'recuperacion'])
  estado!: string;

  @ApiPropertyOptional({ enum: ['entrada'], example: 'entrada' })
  @IsOptional()
  @IsString()
  tipo_movimiento?: string;

  @ApiPropertyOptional({ enum: ['rescate', 'retorno'], example: 'rescate' })
  @IsOptional()
  @IsString()
  motivo?: string;

  @ApiPropertyOptional({
    example: '2024-03-15T10:00:00Z',
    description: 'ISO 8601. Por defecto: NOW()',
  })
  @IsOptional()
  @IsDateString()
  fecha_movimiento?: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/img/rex.jpg' })
  @IsOptional()
  @IsString()
  url_imagen?: string;
}
