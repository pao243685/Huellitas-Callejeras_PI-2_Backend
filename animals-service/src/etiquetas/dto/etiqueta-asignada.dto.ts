import { IsUUID } from 'class-validator';

export class AsignarEtiquetaDto {
  @IsUUID()
  etiqueta_id: string;
}
