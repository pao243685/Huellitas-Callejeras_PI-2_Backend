/* eslint-disable */
import { IsString, IsUUID, IsInt, IsBoolean, IsOptional, IsEnum, IsDecimal } from 'class-validator';
import { TamanoLista, SexoAnimal } from '@prisma/client';

export class CreateAnimalDto {
  @IsString()
  nombre: string;

  @IsString()
  especie: string;

  @IsString()
  raza: string;

  @IsInt()
  edad: number;

  @IsDecimal()
  peso: any;

  @IsEnum(SexoAnimal)
  sexo: SexoAnimal;

  @IsOptional()
  @IsString()
  imagen?: string;

  @IsEnum(TamanoLista)
  tamano: TamanoLista;

  @IsBoolean()
  enfermedad_no_tratable: boolean;

  @IsBoolean()
  discapacidad: boolean;

  @IsBoolean()
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
