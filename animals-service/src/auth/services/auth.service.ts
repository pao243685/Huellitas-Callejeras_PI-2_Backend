/* eslint-disable @typescript-eslint/no-unused-vars */
import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { LoginDto } from '../dto/login.dto';
import { RegisterDto } from '../dto/register.dto';
import { JwtPayload, UserResponse } from '../interfaces/jwt.interfaces';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existingUser = await this.prisma.usuario.findFirst({
      where: { email: registerDto.email },
    });

    if (existingUser) {
      throw new ConflictException('El email ya está registrado');
    }

    const rol = await this.prisma.rol.findUnique({
      where: { id_roles: registerDto.rol_id },
    });

    if (!rol) {
      throw new UnauthorizedException('Rol no encontrado');
    }

    const refugio = await this.prisma.refugio.findUnique({
      where: { id_refugio: registerDto.refugio_id },
    });

    if (!refugio) {
      throw new UnauthorizedException('Refugio no encontrado');
    }

    const hashedPassword = await bcrypt.hash(registerDto.contrasena, 10);

    const user = await this.prisma.usuario.create({
      data: {
        ...registerDto,
        contrasena: hashedPassword,
      },
      select: {
        id_usuario: true,
        nombre: true,
        apellido_p: true,
        apellido_m: true,
        email: true,
        activo: true,
        rol: {
          select: {
            id_roles: true,
            nombre: true,
          },
        },
        refugio: {
          select: {
            id_refugio: true,
            nombre: true,
          },
        },
      },
    });

    const token = this.generateToken({
      id_usuario: user.id_usuario,
      email: user.email,
      rol: user.rol,
      refugio: user.refugio,
    });

    return {
      user,
      access_token: token,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.prisma.usuario.findFirst({
      where: { email: loginDto.email },
      include: {
        rol: true,
        refugio: true,
      },
    });

    console.log('Usuario encontrado:', user ? 'SÍ' : 'NO');
    console.log('Email buscado:', loginDto.email);

    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    console.log('Contraseña en BD:', user.contrasena);
    console.log('Contraseña ingresada:', loginDto.contrasena);

    const isPasswordValid = await bcrypt.compare(
      loginDto.contrasena,
      user.contrasena,
    );

    console.log('Contraseña válida:', isPasswordValid);
    console.log('Usuario activo:', user.activo);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
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

    const { contrasena, ...userWithoutPassword } = user;

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

    const { contrasena, ...userWithoutPassword } = user;
    return userWithoutPassword as UserResponse;
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
