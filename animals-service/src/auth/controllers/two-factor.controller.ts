import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Body,
  UseGuards,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { TwoFactorService } from '../services/two-factor.service';
import { AuthService } from '../services/auth.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { JwtAuthGuard } from '../guards/jwt.guard';
import { CurrentUser } from '../decorators/current-user.decorator';
import { Public } from '../decorators/public.decorator';
import {
  VerifyTwoFactorDto,
  CompleteTwoFactorLoginDto,
} from '../dto/two-factor.dto';
import type { UserResponse } from '../interfaces/jwt.interfaces';

@ApiTags('2FA - Autenticación de dos factores')
@Controller('auth')
export class TwoFactorController {
  constructor(
    private readonly twoFactorService: TwoFactorService,
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * GET /auth/me/2fa
   * Obtiene el estado actual de 2FA del usuario
   * Requiere autenticación con JWT
   */
  @Get('me/2fa')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Obtener estado de 2FA',
    description: 'Verifica si 2FA está habilitado para la cuenta del usuario.',
  })
  @ApiResponse({
    status: 200,
    description: 'Estado de 2FA obtenido',
    schema: {
      example: {
        id_usuario: 'uuid-del-usuario',
        email: 'user@example.com',
        twoFactorEnabled: false,
      },
    },
  })
  @ApiResponse({ status: 401, description: 'No autenticado' })
  async getStatus(@CurrentUser() user: UserResponse) {
    return await this.twoFactorService.getStatus(user.id_usuario);
  }

  /**
   * POST /auth/me/2fa
   * PASO 1: Genera un nuevo secret TOTP e imagen QR
   * Requiere autenticación con JWT
   * El usuario debe escanear el QR y proporcionar el código en PUT
   */
  @Post('me/2fa')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Generar QR para configurar 2FA (PASO 1)',
    description:
      'Genera un nuevo secret y código QR que el usuario debe escanear con su app autenticadora.',
  })
  @ApiResponse({
    status: 201,
    description: 'QR generado. El usuario debe escanear con su app autenticadora.',
    schema: {
      example: {
        secret: 'JBSWY3DPEBLW64TMMQ======',
        qrCodeUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
        message: 'Escanea este QR con tu app autenticadora. Guardaremos el secret cuando verifiques el código.',
      },
    },
  })
  @ApiResponse({ status: 401, description: 'No autenticado' })
  async generateQR(@CurrentUser() user: UserResponse) {
    const result = await this.twoFactorService.generateSecret(
      user.email,
      user.nombre,
    );
    return {
      ...result,
      message: 'Escanea este QR con tu app autenticadora. Guardaremos el secret cuando verifiques el código.',
    };
  }

  /**
   * PUT /auth/me/2fa
   * PASO 2: Activa/Desactiva 2FA después de validar el código TOTP
   * Requiere autenticación con JWT + código válido del authenticator
   * 
   * Body: { token: "123456", secret: "...", enabled: true/false }
   * - Si enabled=true: Activa 2FA (requiere token válido)
   * - Si enabled=false: Desactiva 2FA
   */
  @Put('me/2fa')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Activar/Desactivar 2FA (PASO 2)',
    description:
      'Valida el código TOTP y activa o desactiva 2FA según el parámetro enabled.',
  })
  @ApiResponse({
    status: 200,
    description: '2FA modificado exitosamente',
    schema: {
      example: {
        id_usuario: 'uuid-del-usuario',
        email: 'user@example.com',
        twoFactorEnabled: true,
        message: '2FA activado. Guarda tu secret en un lugar seguro.',
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Código TOTP inválido o datos incompletos' })
  @ApiResponse({ status: 401, description: 'No autenticado' })
  async toggleTwoFactor(
    @CurrentUser() user: UserResponse,
    @Body() body: VerifyTwoFactorDto,
  ) {
    // Si quiere desactivar, no necesita validar código
    if (!body.enabled) {
      const result = await this.twoFactorService.disableTwoFactor(
        user.id_usuario,
      );
      return {
        ...result,
        message: '2FA desactivado.',
      };
    }

    // Si quiere activar, necesita token y secret válidos
    if (!body.token || !body.secret) {
      throw new UnauthorizedException(
        'Para activar 2FA necesitas: token (código de 6 dígitos) y secret',
      );
    }

    const isValid = await this.twoFactorService.verifyToken(body.token, body.secret);
    if (!isValid) {
      throw new UnauthorizedException('Código TOTP inválido o expirado');
    }

    const result = await this.twoFactorService.enableTwoFactor(
      user.id_usuario,
      body.secret,
    );

    return {
      ...result,
      message: '2FA activado correctamente. Guarda tu secret en un lugar seguro.',
    };
  }

  /**
   * DELETE /auth/me/2fa (deprecated)
   * Alias para desactivar 2FA vía DELETE en lugar de PUT
   */
  @Delete('me/2fa')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Desactivar 2FA (método DELETE)',
    description: 'Alias convenience para desactivar. Usa PUT con enabled=false',
  })
  @ApiResponse({
    status: 200,
    description: '2FA desactivado',
  })
  async disableTwoFactor(@CurrentUser() user: UserResponse) {
    const result = await this.twoFactorService.disableTwoFactor(
      user.id_usuario,
    );
    return {
      ...result,
      message: '2FA desactivado.',
    };
  }

  /**
   * POST /auth/2fa/verify
   * Valida el código TOTP durante el login y devuelve JWT
   * NO requiere autenticación con JWT (se usa después de validar email/password)
   * 
   * Flujo:
   * 1. POST /auth/login { email, password } -> respuesta: { requires2FA: true, userId }
   * 2. POST /auth/2fa/verify { userId, token } -> respuesta: { user, access_token }
   */
  @Public()
  @Post('2fa/verify')
  @ApiOperation({
    summary: 'Verificar código TOTP y completar login',
    description:
      'Valida el código TOTP y devuelve JWT. Se usa después de POST /auth/login cuando requires2FA=true.',
  })
  @ApiResponse({
    status: 201,
    description: 'TOTP válido. Login completado.',
    schema: {
      example: {
        user: {
          id_usuario: 'uuid-del-usuario',
          email: 'user@example.com',
          nombre: 'Juan',
          twoFactorEnabled: true,
        },
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Código TOTP inválido o expirado' })
  @ApiResponse({ status: 404, description: 'Usuario no encontrado' })
  async verifyTOTPAndLogin(
    @Body() dto: CompleteTwoFactorLoginDto,
  ) {
    // Obtener el usuario para conseguir el secret almacenado
    const user = await this.twoFactorService.getStatus(dto.userId);

    if (!user.twoFactorEnabled) {
      throw new UnauthorizedException('2FA no está habilitado para este usuario');
    }

    // Buscar el usuario en BD para obtener el secret
    const userWithSecret = (await this.prisma.usuario.findUnique({
      where: { id_usuario: dto.userId },
    })) as { twoFactorSecret?: string | null } | null;

    if (!userWithSecret?.twoFactorSecret) {
      throw new UnauthorizedException('No se encontró el secret de 2FA');
    }

    // Validar el token
    const isValid = await this.twoFactorService.verifyToken(
      dto.token,
      userWithSecret.twoFactorSecret,
    );

    if (!isValid) {
      throw new UnauthorizedException('Código TOTP inválido o expirado');
    }

    // Generar y retornar el JWT
    return await this.authService.generateJwtAfter2FA(dto.userId);
  }
}
