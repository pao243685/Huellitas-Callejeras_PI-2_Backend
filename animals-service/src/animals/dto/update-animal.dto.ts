import { PartialType } from '@nestjs/mapped-types';
import { IsEnum, IsOptional } from 'class-validator';
import { CreateAnimalDto } from './create-animal.dto';

enum EstadoPatch {
  adopcion = 'adopcion',
  recuperacion = 'recuperacion',
}

export class UpdateAnimalDto extends PartialType(CreateAnimalDto) {
  @IsOptional()
  @IsEnum(EstadoPatch, {
    message:
      'Solo se permite cambiar el estado a "adopcion" o "recuperacion" mediante edición directa.',
  })
  estado?: EstadoPatch;
}
