import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'admin@refugio.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'password123' })
  @IsString()
  @MinLength(6)
  contrasena!: string;

  @ApiProperty({
    example: '123456',
    required: false,
    description: 'Código TOTP opcional si el usuario tiene 2FA habilitado',
  })
  @IsOptional()
  @IsString()
  @Length(6, 6, { message: 'El código TOTP debe tener 6 dígitos' })
  totpCode?: string;
}
