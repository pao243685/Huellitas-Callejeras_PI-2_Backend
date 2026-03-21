import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { UserResponse } from '../interfaces/jwt.interfaces';

@Injectable()
export class RefugioOwnershipGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{
      user: UserResponse;
      params: Record<string, string>;
    }>();

    const user = request.user;
    const refugioIdParam = request.params['refugio_id'];

    if (!refugioIdParam) return true;

    if (user?.refugio?.id_refugio !== refugioIdParam) {
      throw new ForbiddenException('No puedes acceder a datos de otro refugio');
    }

    return true;
  }
}
