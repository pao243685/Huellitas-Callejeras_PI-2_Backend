import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { OTP } from 'otplib';
import * as qrcode from 'qrcode';

@Injectable()
export class TwoFactorService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Genera un nuevo secret TOTP y código QR
   * Se usa antes de activar 2FA
   */
  async generateSecret(userEmail: string, userName: string) {
    const otp = new OTP();
    const secret = otp.generateSecret();
    const otpAuthUrl = otp.generateURI({
      issuer: 'Huellitas Callejeras',
      label: userEmail,
      secret,
    });
    const qrCodeUrl = await qrcode.toDataURL(otpAuthUrl);

    return { secret, qrCodeUrl };
  }

  /**
   * Verifica que el token TOTP sea válido
   */
  async verifyToken(token: string, secret: string): Promise<boolean> {
    try {
      const otp = new OTP();
      const result = await otp.verify({ token, secret });
      return result.valid;
    } catch (error) {
      return false;
    }
  }

  /**
   * Activa 2FA por primera vez guardando el secret
   */
  async enableTwoFactor(userId: string, secret: string) {
    return await this.prisma.usuario.update({
      where: { id_usuario: userId },
      data: {
        twoFactorSecret: secret,
        twoFactorEnabled: true,
      },
      select: {
        id_usuario: true,
        email: true,
        twoFactorEnabled: true,
      },
    });
  }

  /**
   * Desactiva 2FA
   */
  async disableTwoFactor(userId: string) {
    return await this.prisma.usuario.update({
      where: { id_usuario: userId },
      data: {
        twoFactorSecret: null,
        twoFactorEnabled: false,
      },
      select: {
        id_usuario: true,
        email: true,
        twoFactorEnabled: true,
      },
    });
  }

  /**
   * Obtiene el estado actual de 2FA del usuario
   */
  async getStatus(userId: string) {
    const user = await this.prisma.usuario.findUnique({
      where: { id_usuario: userId },
      select: {
        id_usuario: true,
        email: true,
        twoFactorEnabled: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Usuario no encontrado');
    }

    return user;
  }
}
