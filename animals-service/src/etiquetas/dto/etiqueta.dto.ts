import { IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateEtiquetaDto {
  @IsString()
  @MaxLength(100)
  nombre: string;

  @IsUUID()
  refugio_id: string;
}
