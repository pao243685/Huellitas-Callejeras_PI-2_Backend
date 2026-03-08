import {
  IsString,
  IsUUID,
  IsInt,
  IsBoolean,
  IsOptional,
  IsEnum,
  IsNumber,
} from 'class-validator';
import { TamanoLista, SexoAnimal, EstadoAnimal } from '@prisma/client';
import { Transform } from 'class-transformer';

const toBoolean = ({ value }: { value: any }): boolean => {
  if (value === true || value === 1) return true;
  if (value === false || value === 0) return false;
  if (typeof value === 'string') {
    return value.trim().toLowerCase() === 'true' || value.trim() === '1';
  }
  return false;
};

export class CreateAnimalDto {
  @IsString()
  nombre: string;

  @IsEnum(EstadoAnimal)
  estado: EstadoAnimal;

  @IsString()
  especie: string;

  @IsString()
  raza: string;

  @IsInt()
  @Transform(({ value }) => parseInt(value, 10))
  edad: number;

  @IsNumber()
  @Transform(({ value }) => parseFloat(value))
  peso: number;

  @IsEnum(SexoAnimal)
  sexo: SexoAnimal;

  @IsOptional()
  @IsString()
  imagen?: string;

  @IsEnum(TamanoLista)
  tamano: TamanoLista;

  @IsBoolean()
  @Transform(toBoolean)
  enfermedad_no_tratable: boolean;

  @IsBoolean()
  @Transform(toBoolean)
  discapacidad: boolean;

  @IsBoolean()
  @Transform(toBoolean)
  es_agresivo: boolean;

  @IsString()
  lugar: string;

  @IsString()
  descripcion: string;

  @IsUUID()
  refugio_id: string;

  @IsUUID()
  usuario_id: string;
}
