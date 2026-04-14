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
      body: Record<string, unknown>;
    }>();

    const user = request.user;

    let refugioId: string | undefined = request.params['refugio_id'];

    if (!refugioId && request.body?.refugio_id) {
      refugioId = request.body.refugio_id as string;
    }

    if (!refugioId) return true;

    if (user?.refugio?.id_refugio !== refugioId) {
      throw new ForbiddenException(
        `No puedes acceder a datos de otro refugio. ` +
          `Tu refugio: ${user?.refugio?.nombre}`,
      );
    }

    return true;
  }
}
