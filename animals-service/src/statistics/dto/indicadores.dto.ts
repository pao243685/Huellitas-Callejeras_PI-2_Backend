import { IsUUID } from 'class-validator';

export class GetIndicadoresDto {
  @IsUUID()
  refugio_id: string;
}
