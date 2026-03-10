import {
  IsEmail,
  IsString,
  IsBoolean,
  IsUUID,
  MinLength,
  MaxLength,
  Matches,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UsersDto {
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

  @ApiProperty({ example: 'Contraseña@123' })
  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/[A-Z]/, {
    message: 'La contraseña debe contener al menos una letra mayúscula',
  })
  @Matches(/[a-z]/, {
    message: 'La contraseña debe contener al menos una letra minúscula',
  })
  @Matches(/[0-9]/, {
    message: 'La contraseña debe contener al menos un número',
  })
  @Matches(/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/, {
    message: 'La contraseña debe contener al menos un carácter especial',
  })
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
