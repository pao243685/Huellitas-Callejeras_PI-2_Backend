import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { LoginDto } from '../dto/login.dto';
import { RegisterDto } from '../dto/register.dto';
import { JwtPayload, UserResponse } from '../interfaces/jwt.interfaces';
import * as bcrypt from 'bcrypt';
import { authenticator } from 'otplib';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    if (!dto.acepta_terminos) {
      throw new BadRequestException('Debes aceptar los términos y condiciones');
    }

    const hashedPassword = await bcrypt.hash(dto.contrasena, 10);

    try {
      await this.prisma.$executeRaw`
        CALL sp_crear_refugio_completo(
          ${dto.nombre}::varchar,
          ${dto.capacidad_max}::integer,
          ${dto.estado}::varchar,
          ${dto.municipio}::varchar,
          ${dto.colonia}::text,
          ${dto.calle}::text,
          ${dto.nombre_usuario}::varchar,
          ${dto.apellido_p}::varchar,
          ${dto.apellido_m}::varchar,
          ${dto.email}::text,
          ${hashedPassword}::text,
          NULL::uuid,
          NULL::uuid,
          NULL::uuid,
          ${dto.num_exterior ?? null}::integer,
          ${dto.num_interior ?? null}::integer
        )
      `;

      const usuario = await this.prisma.usuario.findUnique({
        where: { email: dto.email.toLowerCase().trim() },
        include: { rol: true, refugio: true },
      });

      if (!usuario) {
        throw new BadRequestException(
          'Error al crear el refugio, intenta de nuevo',
        );
      }

      await this.prisma.rol.createMany({
        data: [
          { nombre: 'admin', refugio_id: usuario.refugio_id },
          { nombre: 'colaborador', refugio_id: usuario.refugio_id },
        ],
      });

      const token = this.generateToken({
        id_usuario: usuario.id_usuario,
        email: usuario.email,
        rol: usuario.rol,
        refugio: usuario.refugio,
      });
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { contrasena: _, ...usuarioSinPassword } = usuario;

      return { user: usuarioSinPassword, access_token: token };
    } catch (error: unknown) {
      if (
        error instanceof Error &&
        error.message.includes('ya esta registrado')
      ) {
        throw new ConflictException('El email ya está registrado');
      }
      throw error;
    }
  }

  async login(loginDto: LoginDto) {
    const user = await this.prisma.usuario.findFirst({
      where: { email: loginDto.email },
      include: {
        rol: true,
        refugio: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.contrasena,
      user.contrasena,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!user.activo) {
      throw new UnauthorizedException('Usuario inactivo');
    }

    // Si 2FA está habilitado, no retornar JWT aún
    if (user.twoFactorEnabled) {
      const twoFactorSecret = (user as { twoFactorSecret?: string | null })
        .twoFactorSecret;

      if (loginDto.totpCode && twoFactorSecret) {
        const isValidToken = authenticator.verify({
          token: loginDto.totpCode,
          secret: twoFactorSecret,
        });

        if (!isValidToken) {
          throw new UnauthorizedException('Código TOTP inválido o expirado');
        }

        const token = this.generateToken({
          id_usuario: user.id_usuario,
          email: user.email,
          rol: user.rol,
          refugio: user.refugio,
        });

        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { contrasena: _, ...userWithoutPassword } = user;

        return {
          user: userWithoutPassword,
          access_token: token,
        };
      }

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { contrasena: _, twoFactorSecret: __, ...userBasic } = user;
      return {
        requires2FA: true,
        userId: user.id_usuario,
        user: userBasic,
        message: 'Por favor, ingresa tu código de verificación de 2 factores',
      };
    }

    const token = this.generateToken({
      id_usuario: user.id_usuario,
      email: user.email,
      rol: user.rol,
      refugio: user.refugio,
    });
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { contrasena: _, ...userWithoutPassword } = user;

    return {
      user: userWithoutPassword,
      access_token: token,
    };
  }

  async validateUser(userId: string): Promise<UserResponse | null> {
    const user = await this.prisma.usuario.findUnique({
      where: { id_usuario: userId },
      include: {
        rol: true,
        refugio: true,
      },
    });

    if (!user || !user.activo) {
      return null;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { contrasena: _, ...userWithoutPassword } = user;
    return userWithoutPassword as UserResponse;
  }

  /**
   * Genera JWT después de validar exitosamente 2FA
   * Se usa cuando el usuario proporciona un código TOTP válido
   */
  async generateJwtAfter2FA(userId: string) {
    const user = await this.prisma.usuario.findUnique({
      where: { id_usuario: userId },
      include: {
        rol: true,
        refugio: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Usuario no encontrado');
    }

    if (!user.activo) {
      throw new UnauthorizedException('Usuario inactivo');
    }

    const token = this.generateToken({
      id_usuario: user.id_usuario,
      email: user.email,
      rol: user.rol,
      refugio: user.refugio,
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { contrasena: _, ...userWithoutPassword } = user;

    return {
      user: userWithoutPassword,
      access_token: token,
    };
  }

  private generateToken(user: {
    id_usuario: string;
    email: string;
    rol: { id_roles: string; nombre: string };
    refugio: { id_refugio: string; nombre: string };
  }): string {
    const payload: JwtPayload = {
      sub: user.id_usuario,
      email: user.email,
      rol: user.rol.nombre,
      refugio: user.refugio.id_refugio,
    };

    return this.jwtService.sign(payload);
  }
}
