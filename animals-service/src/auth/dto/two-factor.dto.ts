import { IsNotEmpty, IsString, IsBoolean, Length, Optional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * DTO para PUT /auth/me/2fa
 * Activa o desactiva 2FA
 */
export class VerifyTwoFactorDto {
  @ApiProperty({
    description: 'Código TOTP de 6 dígitos desde el authenticator',
    example: '123456',
    required: false,
  })
  @Optional()
  @IsString()
  @Length(6, 6, { message: 'El código debe ser de 6 dígitos' })
  token?: string;

  @ApiProperty({
    description: 'Secret TOTP (se proporciona en POST /auth/me/2fa)',
    example: 'JBSWY3DPEBLW64TMMQ======',
    required: false,
  })
  @Optional()
  @IsString()
  secret?: string;

  @ApiProperty({
    description: 'true para activar, false para desactivar',
    example: true,
  })
  @IsNotEmpty({ message: 'enabled es requerido' })
  @IsBoolean()
  enabled: boolean;
}

/**
 * DTO para POST /auth/2fa/verify
 * Valida el código TOTP durante login y devuelve JWT
 */
export class CompleteTwoFactorLoginDto {
  @ApiProperty({
    description: 'ID del usuario',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsNotEmpty({ message: 'El userId es requerido' })
  @IsString()
  userId: string;

  @ApiProperty({
    description: 'Código TOTP de 6 dígitos desde el authenticator',
    example: '123456',
  })
  @IsNotEmpty({ message: 'El código TOTP es requerido' })
  @IsString()
  @Length(6, 6, { message: 'El código debe ser de 6 dígitos' })
  token: string;
}
