import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserResponse } from '../interfaces/jwt.interfaces';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user: UserResponse }>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Sin autenticación');
    }

    const userRole: string = user.rol?.nombre;

    if (!requiredRoles.includes(userRole)) {
      throw new ForbiddenException(
        `Requiere rol: ${requiredRoles.join(' o ')}. Tu rol: ${userRole}`,
      );
    }

    return true;
  }
}
