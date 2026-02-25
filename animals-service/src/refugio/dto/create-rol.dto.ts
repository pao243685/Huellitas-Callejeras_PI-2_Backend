import { IsString, IsUUID } from 'class-validator';

export class CreateRolDto {
  @IsString()
  nombre: string;

  @IsUUID()
  refugio_id: string;
}
