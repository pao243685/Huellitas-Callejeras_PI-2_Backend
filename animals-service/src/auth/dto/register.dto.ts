import {
  IsEmail,
  IsString,
  IsBoolean,
  IsUUID,
  MinLength,
  MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'Juan' })
  @IsString()
  @MaxLength(100)
  nombre: string;

  @ApiProperty({ example: 'Pérez' })
  @IsString()
  @MaxLength(100)
  apellido_p: string;

  @ApiProperty({ example: 'García' })
  @IsString()
  @MaxLength(100)
  apellido_m: string;

  @ApiProperty({ example: 'juan@refugio.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123' })
  @IsString()
  @MinLength(6)
  contrasena: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  activo: boolean;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  @IsUUID()
  rol_id: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  @IsUUID()
  refugio_id: string;
}
