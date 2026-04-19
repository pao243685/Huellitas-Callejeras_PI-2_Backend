import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { UserResponse } from '../interfaces/jwt.interfaces';

@Injectable()
export class RefugioBodyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{
      user: UserResponse;
      body: Record<string, unknown>;
    }>();

    const user = request.user;
    const refugioIdBody = request.body?.refugio_id as string | undefined;

    if (!refugioIdBody) return true;

    if (user?.refugio?.id_refugio !== refugioIdBody) {
      throw new ForbiddenException(
        `No puedes operar sobre otro refugio. ` +
          `Tu refugio: ${user?.refugio?.nombre ?? 'desconocido'}`,
      );
    }
    return true;
  }
}
