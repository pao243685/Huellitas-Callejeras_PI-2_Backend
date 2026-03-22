import {
  IsString,
  IsInt,
  IsOptional,
  IsEmail,
  MinLength,
  Matches,
  MaxLength,
  IsBoolean,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';

export class RegisterDto {
  @ApiProperty({ example: 'Refugio Esperanza' })
  @IsString()
  @MaxLength(100)
  nombre: string;

  @ApiProperty({ example: 30 })
  @IsInt()
  @Transform(({ value }) => parseInt(value, 10))
  capacidad_max: number;

  @ApiProperty({ example: 'Chiapas' })
  @IsString()
  estado: string;

  @ApiProperty({ example: 'Tuxtla Gutiérrez' })
  @IsString()
  municipio: string;

  @ApiProperty({ example: 'Centro' })
  @IsString()
  colonia: string;

  @ApiProperty({ example: 'Av. Principal' })
  @IsString()
  calle: string;

  @ApiProperty({ example: 123, required: false })
  @IsOptional()
  @IsInt()
  @Transform(({ value }) => (value ? parseInt(value, 10) : null))
  num_exterior?: number;

  @ApiProperty({ example: 4, required: false })
  @IsOptional()
  @IsInt()
  @Transform(({ value }) => (value ? parseInt(value, 10) : null))
  num_interior?: number;

  @ApiProperty({ example: 'Valentina' })
  @IsString()
  @MaxLength(100)
  nombre_usuario: string;

  @ApiProperty({ example: 'García' })
  @IsString()
  @MaxLength(100)
  apellido_p: string;

  @ApiProperty({ example: 'López' })
  @IsString()
  @MaxLength(100)
  apellido_m: string;

  @ApiProperty({ example: 'juan@refugio.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Contrasena@123' })
  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/[A-Z]/, { message: 'Debe contener al menos una mayúscula' })
  @Matches(/[a-z]/, { message: 'Debe contener al menos una minúscula' })
  @Matches(/[0-9]/, { message: 'Debe contener al menos un número' })
  @Matches(/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/, {
    message: 'Debe contener al menos un carácter especial',
  })
  contrasena: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  acepta_terminos: boolean;
}
